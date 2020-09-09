#!/usr/bin/env python

from __future__ import print_function

import click
from collections import defaultdict, namedtuple
import json
import logging
import multiprocessing as mp
import os
import Queue
import re
import shutil
import subprocess as sp
import sys
import threading
import time
import yaml

CLANG_TIDY_OUTPUT_REGEX = r'^(?P<path>[^:\n]+):(?P<line>\d+):(?P<column>\d+): (?P<severity>[^:]+): (?P<message>.+) \[(?P<type>.*)\]\n'

CLANG_TIDY_OUTPUT_PATTERN = re.compile(CLANG_TIDY_OUTPUT_REGEX, re.MULTILINE)

Fix = namedtuple('Fix', [
    'path',
    'line',
    'column',
    'severity',
    'message',
    'type',
    'snippet',
    'indicator',
    'suggestion',
])

# this is used for whitelist. The fields must be a subset of `Fix`.
KnownIssue = namedtuple('KnownIssue', [
    'path',
    'column',
    'message',
    'snippet',
])


def fix2known_issue(fix):
    d = dict([(k, getattr(fix, k)) for k in KnownIssue._fields])
    return KnownIssue(**d)


def thread_init(task_q, result_q, workspace_root, excludes, clang_tidy):
    while True:
        try:
            target = task_q.get()
            fixes = run_clang_tidy(target, workspace_root, excludes, clang_tidy)
            for f in fixes:
                result_q.put(f)
        finally:
            task_q.task_done()

def run_clang_tidy(target, workspace_root, excludes, clang_tidy):
    args = [clang_tidy, target]
    t0 = time.time()
    popen = sp.Popen(args, stdout=sp.PIPE, stderr=sp.PIPE)
    stdout, stderr = popen.communicate()
    if popen.returncode == 0:
        logging.debug('''
clang-tidy succeeded: %s

--- BEGIN: stdout ---
%s
--- END: stdout ---
''', ' '.join(args), stdout)
    else:
        logging.debug('''
clang-tidy failed (returncode: %d): %s

--- BEGIN: stderr ---
%s
--- END: stderr ---
''', popen.returncode, ' '.join(args), stderr)

    t1 = time.time()
    logging.debug('Took %2.3f secs to for %s', t1 - t0, target)

    if not stdout:
        return []

    fixes = parse_clang_tidy_output(stdout)

    # Relativise paths in `fixes`, and filter the ones outside workspace_root

    exclude_prefixes = set(excludes)
    def pred(relpath):
        if relpath.startswith('../'):
            return False
        for prefix in exclude_prefixes:
            if relpath.startswith(prefix):
                return False
        return True

    filtered = []
    for fix in fixes:
        fix = fix._replace(path=os.path.relpath(fix.path, workspace_root))
        if pred(fix.path):
            filtered.append(fix)

    return filtered


def parse_clang_tidy_output(output):
    prev_match = CLANG_TIDY_OUTPUT_PATTERN.search(output)
    if not prev_match:
        return []

    fix = None
    fixes = []
    while True:
        match = CLANG_TIDY_OUTPUT_PATTERN.search(output, prev_match.end())
        if not match:
            fixes.append(make_fix(prev_match, output[prev_match.end():], fix))
            break

        fix = make_fix(prev_match, output[prev_match.end():match.start()], fix)
        fixes.append(fix)
        prev_match = match

    return fixes


def make_fix(match, rest, fix):
    lines = rest.splitlines()
    if len(lines) == 0:
        return Fix(
            snippet=fix.snippet if fix else '',
            indicator=fix.indicator if fix else '',
            suggestion='',
            **match.groupdict()
        )
    elif len(lines) == 1:
        return Fix(
            snippet=fix.snippet if fix else '',
            indicator=fix.indicator if fix else '',
            suggestion=lines[0].strip(),
            **match.groupdict()
        )
    elif len(lines) >= 2:
        return Fix(
            snippet=lines[0],
            indicator=lines[1],
            suggestion='\n'.join(lines[2:]).strip(),
            **match.groupdict()
        )
    else:
        logging.warning('Unexpected lines in %s: %s', match.group('path'), rest)
        return Fix(
            snippet=fix.snippet if fix else '',
            indicator=fix.indicator if fix else '',
            suggestion='',
            **match.groupdict()
        )


def write_to_file(fixes, filename):
    issues = [dict(fix2known_issue(f)._asdict()) for f in fixes]
    with open(filename, 'w') as f:
        yaml.dump(issues, f, default_flow_style=False)


def parallel_run_clang_tidy(files, workspace_root, exclude_paths, nproc, clang_tidy):
    task_q = Queue.Queue()
    result_q = Queue.Queue()
    for i in range(nproc):
        t = threading.Thread(target=thread_init, args=(
            task_q,
            result_q,
            workspace_root,
            exclude_paths,
            clang_tidy,
        ))
        t.daemon = True
        t.start()

    t0 = time.time()

    for t in files:
        task_q.put(t)

    while not task_q.empty():
        logging.info('%d clang-tidy processes running: %3d / %3d',
                     nproc,
                     max(0, len(files) - task_q.qsize() - nproc),
                     len(files))
        time.sleep(5)

    # block until all tasks are done
    task_q.join()

    t1 = time.time()
    logging.info('Finished clang-tidy for %d files. (took %.3f secs)', len(files), t1 - t0)

    results = []
    while not result_q.empty():
        results.append(result_q.get())

    return results


def target_files(paths, compile_commands, workspace_root):
    # calculate the files to be checked.
    # union of files under `paths` and what is listed in `compile_commands_json`

    logging.info('Searching %s for files to be checked...', workspace_root)
    t0 = time.time()

    # list all files under `paths`
    abspaths = []
    for fn in (paths or ['.']):
        if os.path.isdir(fn):
            for dir, _, fns in os.walk(fn):
                abspaths.extend([os.path.join(dir, f) for f in fns])
        else:
            abspaths.append(os.path.join(workspace_root, fn))

    # convert to relative path. filter out ones outside workspace
    relpaths = filter(lambda p: not p.startswith('../'),
                      map(lambda p: os.path.relpath(p, workspace_root), abspaths))

    # files known to CMake
    known_files = [os.path.relpath(c['file'], workspace_root) for c in compile_commands]

    # files to be checked
    targets = list(set(known_files).intersection(set(relpaths)))
    t1 = time.time()
    logging.info(
        'Found %d files to be checked (took %.3f secs. %d files scanned. %d files filtered unknown to CMake)',
        len(targets),
        t1 - t0,
        len(relpaths),
        len(relpaths) - len(targets),
    )

    return targets


@click.group()
def cli():
    pass

@cli.command()
@click.option('-c', '--compile-commands-json', required=True, type=str,
              help='Path to compile_commands.json file, which is available by running catkin_make/cmake with `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` option')
@click.option('-w', '--whitelist-file', default=None, type=str,
              help="Path to a YAML file containing known issues that won't be reported again.")
@click.option('-r', '--workspace-root', required=True, type=str,
              help='Path to the root directory of this workspace.')
@click.option('-x', '--exclude', multiple=True, type=str,
              help='Relative path from workspace root. The file of this path, or files under this directory will be excluded from the check. This option may be specified multiple times.')
@click.option('--new-whitelist-file', default=None, type=str,
              help="Path to a YAML file to which an updated whitelist file is written.")
@click.option('--nproc', type=int, default=mp.cpu_count(),
              help='Number of CPUs. This affects how many clang-tidy processes run in parallel.')
@click.option('--clang-tidy', envvar='CLANG_TIDY', type=str, default=None,
              help='Path to clang-tidy binary. If unspecified, the one in PATH will be used.')
@click.argument('path', nargs=-1, type=click.Path(exists=True))
def check(compile_commands_json,
          whitelist_file,
          workspace_root,
          exclude,
          new_whitelist_file,
          nproc,
          clang_tidy,
          path):
    with open(compile_commands_json, 'r') as f:
        compile_commands = json.load(f)

    if whitelist_file is None:
        known_issues = set()
    else:
        logging.info('Reading %s ...', whitelist_file)
        t0 = time.time()
        with open(whitelist_file, 'r') as f:
            issues = []
            # There is an environment where this script runs with
            # an unexpeced version of Python with older PyYaml
            # that does not have `FullLoader` property.
            # Until we figure it out, remove `Loader` argument.
            #
            # for y in yaml.load(f, Loader=yaml.FullLoader):
            for y in yaml.load(f):
                issues.append(KnownIssue(**y))
            known_issues = set(issues)
        t1 = time.time()
        logging.info('Found %d known issues. (took %.3f secs)', len(known_issues), t1 - t0)

    targets = target_files(path, compile_commands, workspace_root)

    # Copy compile_commands.json to workspace_root
    ccj_in_workspace = os.path.join(workspace_root, 'compile_commands.json')
    if not os.path.isfile(ccj_in_workspace):
        os.symlink(compile_commands_json, ccj_in_workspace)

    fixes = parallel_run_clang_tidy(targets, workspace_root, exclude, nproc, clang_tidy)

    # dedupe & sort
    fixes = sorted(list(set(fixes)), key=lambda f: (f.path, f.line, f.column))

    returncode = 0
    idx = 0
    num_ignored = 0
    for fix in fixes:
        if fix2known_issue(fix) in known_issues:
            num_ignored += 1
        else:
            returncode = 1
            print('-------- %4d. %s --------' % (idx + 1, fix.severity))
            print('File: %s (line %d)' % (fix.path, int(fix.line)))
            print('> %s' % fix.snippet)
            print('> %s' % fix.indicator)
            print('')
            print('FixType: %s' % fix.type)
            print('Message: %s' % fix.message)
            print('Suggestion: %s' % (fix.suggestion or 'N/A'))
            print('')

            idx += 1

    print('%d issues are reported.' % (len(fixes) - num_ignored))
    print('%d issues are not reported because they are already known.' % num_ignored)

    if new_whitelist_file:
        write_to_file(fixes, new_whitelist_file)
        logging.info('Whitelist is updated and saved: %s', new_whitelist_file)

    sys.exit(returncode)


if __name__ == "__main__":
    logging.basicConfig(
        stream=sys.stdout,
        format='%(asctime)s - %(levelname)s - %(message)s',
        level=logging.INFO)
    cli()
