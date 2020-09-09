#!/usr/bin/env python

# Adapted from https://github.com/ros/catkin/blob/kinetic-devel/cmake/test/run_tests.py

from __future__ import print_function

import argparse
import os
import sys
import subprocess
import xml.etree.ElementTree as ET

from catkin.test_results import ensure_junit_result_exist, remove_junit_result


def main(argv=sys.argv[1:]):
    parser = argparse.ArgumentParser(description='Runs the test command passed as an argument and verifies that the expected result file has been generated.')
    parser.add_argument('results', help='The path to the xunit result file')
    parser.add_argument('command', nargs='+', help='The test command to execute')
    parser.add_argument('--working-dir', nargs='?', help='The working directory for the executed command')
    parser.add_argument('--return-code', action='store_true', default=False, help='Set the return code based on the success of the test command')
    args = parser.parse_args(argv)

    remove_junit_result(args.results)

    work_dir_msg = ' with working directory "%s"' % args.working_dir if args.working_dir is not None else ''
    cmds_msg = ''.join(['\n  %s' % cmd for cmd in args.command])
    print('-- run_tests.py: execute commands%s%s' % (work_dir_msg, cmds_msg))

    rc = 0
    for cmd in args.command:
        rc = subprocess.call(cmd, cwd=args.working_dir, shell=True)
        if rc != 0:
            break

    print('-- run_tests.py: verify result "%s"' % args.results)
    no_errors = ensure_junit_result_exist(args.results)
    if not no_errors:
        rc = 1
    else:
        tree = ET.ElementTree(None, args.results)
        root = tree.getroot()
        root.attrib['tests'] = str(int(root.attrib['tests']) + 1)

        if rc != 0:
            failures = 1
            message = '<failure message="Return code was expected to be 0, but got {}"></failure>'.format(rc)
            root.attrib['failures'] = str(int(root.attrib['failures']) + 1)
        else:
            failures = 0
            message = ''

        # subprocess call failed; write a test result into the XML file
        newsuite = ET.fromstring("""
<testsuite name="return_code" tests="1" failures="{}" disabled="0" errors="0" time="0">
  <testcase name="return_code" status="run" time="0" classname="RetCode">
    {}
  </testcase>
</testsuite>
        """.format(failures, message))
        root.append(newsuite)
        tree.write(args.results, xml_declaration=True)

    if args.return_code:
        return rc
    return 0


if __name__ == '__main__':
    sys.exit(main())
