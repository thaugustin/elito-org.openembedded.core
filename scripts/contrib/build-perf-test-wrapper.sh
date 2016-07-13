#!/bin/bash
#
# Build performance test script wrapper
#
# Copyright (c) 2016, Intel Corporation.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
#
# This script is a simple wrapper around the actual build performance tester
# script. This script initializes the build environment, runs
# oe-build-perf-test and archives the results.

script=`basename $0`
usage () {
    echo "Usage: $script [COMMITISH]"
}

if [ $# -gt 1 ]; then
    usage
    exit 1
fi
commitish=$1

echo "Running on `uname -n`"

if ! git_topdir=$(git rev-parse --show-toplevel); then
        echo "The current working dir doesn't seem to be a git clone. Please cd there before running `basename $0`"
        exit 1
fi

cd "$git_topdir"

if [ -n "$commitish" ]; then
    # Checkout correct revision
    echo "Checking out $commitish"
    git fetch &> /dev/null
    git checkout HEAD^0 &> /dev/null
    git branch -D $commitish &> /dev/null
    if ! git checkout -f $commitish &> /dev/null; then
        echo "Git checkout failed"
        exit 1
    fi
fi

# Setup build environment
timestamp=`date "+%Y%m%d%H%M%S"`
git_rev=$(git rev-parse --short HEAD)  || exit 1
base_dir="$git_topdir/build-perf-test"
build_dir="$base_dir/build-$git_rev-$timestamp"
results_dir="$base_dir/results-$git_rev-$timestamp"
globalres_log="$base_dir/globalres.log"

mkdir -p "$base_dir"
source ./oe-init-build-env $build_dir >/dev/null || exit 1

# Additional config
auto_conf="$build_dir/conf/auto.conf"
echo 'MACHINE = "qemux86"' > "$auto_conf"
echo 'BB_NUMBER_THREADS = "8"' >> "$auto_conf"
echo 'PARALLEL_MAKE = "-j 8"' >> "$auto_conf"
echo "DL_DIR = \"$base_dir/downloads\"" >> "$auto_conf"
# Disabling network sanity check slightly reduces the variance of timing results
echo 'CONNECTIVITY_CHECK_URIS = ""' >> "$auto_conf"
# Possibility to define extra settings
if [ -f "$base_dir/auto.conf.extra" ]; then
    cat "$base_dir/auto.conf.extra" >> "$auto_conf"
fi

# Run actual test script
if ! oe-build-perf-test --out-dir "$results_dir" \
                        --globalres-file "$globalres_log" \
                        --lock-file "$base_dir/oe-build-perf.lock"; then
    echo "oe-build-perf-test script failed!"
    exit 1
fi

echo -ne "\n\n-----------------\n"
echo "Global results file:"
echo -ne "\n"

cat "$globalres_log"

echo -ne "\n\n-----------------\n"
echo "Archiving results dir..."
archive_dir=~/perf-results/archives
mkdir -p "$archive_dir"
results_basename=`basename "$results_dir"`
results_dirname=`dirname "$results_dir"`
tar -czf "$archive_dir/`uname -n`-${results_basename}.tar.gz" -C "$results_dirname" "$results_basename"

rm -rf "$build_dir"
rm -rf "$results_dir"

echo "DONE"
