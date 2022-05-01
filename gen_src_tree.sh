#!/bin/bash

SUBDIRS=${1:-10}
DEPTH=${2:-4}
OUT=${3:-$(pwd)/output/src}

rm -rf ${OUT}

function gendir {
	local curdir=$1
	local curdepth=$2
	local curlib=$(echo $curdir | tr / _ | tr - _)
	install -d $curdir
	sed s/FOO_FUNC/$curlib/ < foo.c > $curdir/foo.c
	if [ $curdepth -eq 1 ]; then
		sed s/FOO_FUNC/$curlib/ < main.c > $curdir/main.c

    # Make
		echo "obj-y += main.o" >> $curdir/Makefile

    # CMake
		echo "set(CMAKE_NINJA_FORCE_RESPONSE_FILE 1)" >> $curdir/CMakeLists.txt
		echo "ADD_EXECUTABLE(foo main.c)" >> $curdir/CMakeLists.txt
		echo "TARGET_LINK_LIBRARIES(foo $curlib)" >> $curdir/CMakeLists.txt

    # Meson
    echo "project('benchy-bench', 'c')" >> $curdir/meson.build
	fi

	echo "void $curlib();" > $curdir/foo.h

  # Make
	echo "obj-y += foo.o" >> $curdir/Makefile

  # CMake
	echo "ADD_LIBRARY($curlib STATIC foo.c)" >> $curdir/CMakeLists.txt

  # Meson
  echo "${curlib}_link_libs = []" >> $curdir/meson.build
  echo "args = []" >> $curdir/meson.build
  echo "args += '-DCURDIR=\"$curdir\"'" >> $curdir/meson.build

	if [ $curdepth -ne $DEPTH ]; then
		for i in `seq 1 ${SUBDIRS}`; do
			local tmp=$i
			gendir $curdir/$tmp $((curdepth + 1))
			sed "s/>/>\n#include \"$tmp\/foo.h\"\n/" -i $curdir/foo.c
			sed "s/^}/\t${curlib}_${tmp}\(\);\n}/" -i $curdir/foo.c

      # Make
			echo "obj-y += $tmp/" >> $curdir/Makefile

      # CMake
			echo "ADD_SUBDIRECTORY($tmp)" >> $curdir/CMakeLists.txt
			echo "TARGET_LINK_LIBRARIES($curlib ${curlib}_$tmp)" >> $curdir/CMakeLists.txt

      # Meson
      echo "subdir('$tmp')" >> $curdir/meson.build
      echo "${curlib}_link_libs += ${curlib}_$tmp" >> $curdir/meson.build
		done
	fi

  # Meson
  echo "$curlib = static_library('$curlib', 'foo.c', link_with: ${curlib}_link_libs, c_args: args)" >> $curdir/meson.build
	if [ $curdepth -eq 1 ]; then
    echo "executable('foo', 'main.c', link_with: $curlib, c_args: args)" >> $curdir/meson.build
	fi

  #======================

  # Make
	echo "cflags-y = -D'CURDIR=$curdir'" >> $curdir/Makefile

  # CMake
	echo "set(CMAKE_C_FLAGS \"\${CMAKE_C_FLAGS} -D'CURDIR=$curdir'\")" >> $curdir/CMakeLists.txt
}

echo "Generating sources under ${OUT}: tree depth ${DEPTH} subdirs ${SUBDIRS}"

gendir ${OUT} 1
