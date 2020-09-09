#!/bin/bash
#
# Exit with 0 if all .h & .cpp files in our source tree are formatted correctly according to
# clang-format.  Otherwise, exit with non-zero.
#

RED='\033[0;31m'
NC='\033[0m' # No Color

fix_in_place=0
check_modified_files=0
verbose=0

# check arguments
while getopts 'fgv' flag; do
  case "${flag}" in
    f)
        fix_in_place=1
        ;;
    g)
        check_modified_files=1
        ;;
    v)
        verbose=1
        ;;
    \?)
        echo "Invalid option: ${OPTARG}" 1>&2
        echo "  -f: fix files in-place." 1>&2
        echo "  -g: check files that are changed in this git commit." 1>&2
        echo "  -v: verbose." 1>&2
        exit 1
        ;;
  esac
done

shopt -s nullglob # Sets nullglob
shopt -s nocaseglob # Sets nocaseglob

cd $(git rev-parse --show-toplevel)

SOURCES=()
if [[ $check_modified_files -ne 0 ]]; then
    for path in $(git diff-index --cached --diff-filter=ACMR --name-only HEAD); do
        if [[ $path != *third_party/* && $path != *device_drivers/inertial_sense_ros/lib/* && $path != */node_modules/* ]]; then
            ext=${path##*.}
            if [[ $ext == c || $ext == cpp || $ext == h || $ext == hpp || $ext == hxx ]]; then
                SOURCES+=("$path")
            fi
        fi
    done
else
    # look for all c, cpp, h, hpp, hxx in the project, except for those in the following folders
    SOURCES=$(find . \
                   -not -path "*third_party/*" \
                   -not -path "*device_drivers/inertial_sense_ros/lib/*" \
                   -not -path "*/node_modules/*" \
                   -regex '.*\.\(c\|cpp\|h\|hpp\|hxx\)$' -print)
fi

FAILED=0
FAILED_FILES=()

formatted=$(mktemp)
diff_out=$(mktemp)
for f in ${SOURCES[@]}; do
  clang-format-6.0 -style=file -fallback-style=none $f > $formatted
  diff -u $f $formatted > $diff_out; rc=$?

  # Display result
  if [[ $verbose -eq 0 ]]; then
    echo -n "checking format $f... "
    if [[ $rc -eq 0 ]]; then
      echo "pass"
    else
      echo -e "${RED}FAIL${NC}"
    fi
  else
    if [[ $rc -eq 0 ]]; then
      echo "File $f is clean."
    else
      echo "File $f has formatting errors."
      cat $diff_out
    fi
  fi

  # Fix in place
  if [[ $fix_in_place -eq 1 ]]; then
    cp $formatted $f
  fi

  # Increment failure count
  if [[ $rc -ne 0 ]]; then
    FAILED=1;
    FAILED_FILES+=("$f")
  fi
done

shopt -u nocaseglob # Unsets nocaseglob
shopt -u nullglob # Unsets nullglob

if [[ $fix_in_place -ne 0 && $verbose -ne 0 ]]; then
  echo
  if [ $FAILED -ne 0 ]; then
    echo "Files with formatting errors:"
    echo "-----------------------------"
    for f in "${FAILED_FILES[@]}"; do
      echo "$f"
    done
    echo "-----------------------------"
  else
    echo "No formatting errors found"
  fi
  echo
fi

exit $FAILED
