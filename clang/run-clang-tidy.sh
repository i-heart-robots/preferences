#!/bin/bash -e

ws_root=$(git rev-parse --show-toplevel)
cd $ws_root

ccj=../../build/compile_commands.json
clang_tidy_bin=/usr/bin/clang-tidy-7
whitelist_file=.clang-tidy-whitelist.yaml
nproc=$(nproc)

while getopts 'c:t:p:n' o; do
    case $o in
        c)
            ccj=$OPTARG
            ;;
        t)
            clang_tidy_bin=$OPTARG
            ;;
        n)
            whitelist_file=''
            ;;
        p)
            nproc=$OPTARG
            ;;
        \?)
            echo "Invalid option: ${OPTARG}"
            exit 1
    esac
done
shift $((OPTIND-1))

if [ -z "$whitelist_file" ]; then
   whitelist_arg=''
else
   whitelist_arg="-w $whitelist_file"
fi

if [ ! -f $ccj ]; then
    echo "File not found: $ccj"
    echo "Have you run catkin_make with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON option?"
    exit 1
fi

if [ ! -f $clang_tidy_bin ]; then
    echo 'clang-tidy not found. To install, run the commands below.'
    echo '  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -'
    echo '  apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-7 main"'
    echo '  apt-get update && apt-get install clang-tidy-7'
    exit 1
fi


./build/scripts/run-clang-tidy.py \
    check \
    -c $ccj \
    $whitelist_arg \
    -r $ws_root \
    -x third_party \
    -x device_drivers/inertial_sense_ros/lib \
    --new-whitelist-file /tmp/.clang-tidy-whitelist \
    --clang-tidy $clang_tidy_bin \
    --nproc $nproc \
    $@
