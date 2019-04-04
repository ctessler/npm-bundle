#!/bin/bash
BASE="`basename \"$0\"`"
#
# This is not a script for end users, as such it is not documented to
# discourage anyone from using it without the utmost of confidence.
#
name=$1
S=$2

if [ -z "$name" ] ; then
	echo "${BASE} no name"
	exit -1;
fi

if [ -z "$S" ] ; then
	echo "${BASE} no count"
	exit -1;
fi
dir="`dirname ${name}`"
name="`basename ${name}`"
file="${PWD}/${name}.sched"

sched-test.sh -h > $file
for s in $(seq 1 1 $S); do
	num=$(printf "%04d" $s)
	cd $dir >/dev/null
	sched-test.sh -H ${name}-${num}.ts >> $file
	cd - >/dev/null
	if [ $? -ne 0 ] ; then
		echo "sched-test.sh ${name}-${num}.ts >> $file failed"
		exit -1
	fi
done

exit 0
