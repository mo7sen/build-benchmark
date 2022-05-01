#!/bin/bash

NPROC=$((2*$(nproc)))

targets="kbuild nrecur static cmake cninja ninja meson"

function build_targets {
	for target in $targets; do
		echo -n "$target: "
		command time -f %e make $target -j$NPROC 1> /dev/null
		sync
	done
	echo -e "\n"
}

leaf="output/src"

for i in `seq 2 5`; do

rm -rf output
mkdir output
./gen_src_tree.sh 10 $i output/src
sync

leaf="$leaf/1"

echo -e "Test with Tree depth = $i\n"

echo -e "Cold start\n"
build_targets

echo -e "Rebuild full\n"
find output/src -name "*.c" -exec touch {} \;
build_targets

echo -e "Rebuild leaf ($leaf/foo.h)\n"
touch "$leaf/foo.h"
build_targets

echo -e "Nothing to be done\n"
build_targets

done
