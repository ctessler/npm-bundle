#!/bin/bash
# (setq sh-indentation 8)
# (setq sh-basic-offset 8)

# J limits the number of jobs that this will fork. It can be set by
# the user in their environment and is hidden with good purpose. This
# script is a fork-bomb a machine.
J=${J:-5}

# Shared library functions
contdir="`dirname \"$0\"`"
source ${contdir}/shared.sh

#
# Usage
#
function usage {
	b="`basename $0`"
	cat <<EOF
Generates the schedulability test data for the aggregate of S sets 
$b [OPTIONS] <DIRECTORY>
OPTIONS: *ALL* options are required and *must* match incip-sets.sh
	-c/--count <INT>		Tasks per configuration
	-u/--min-util <FLOAT>		Utilizations min.
	-U/--max-util <FLOAT>		Utilizations max.

DIRECTORY:
	Must be a directory containing .ts files produced by
	cs-tasks.sh

EXAMPLE:
	$b -u .1 -U .9 -c 1000 cs/
EOF
	exit 1
}

# Artificial Entry Point
function main {
	#
	# Handle those arguments
	#
	short_opts="c:u:U:"
	long_opts="count:,min-util:,max-util"

	args=`getopt -o ${short_opts} -l ${long_opts} -- "$@"`

	eval set -- ${args}
	while true ; do
		case "$1" in
			--min-util) ;&
			-u)
				MINU=$2 ; shift 2
				;;
			--max-util) ;&
			-U)
				MAXU=$2 ; shift 2
				;;
			--count) ;&
			-c)
				COUNT=$2 ; shift 2
				;;
			--)
				shift ; break
				;;
		esac
	done

	if [ -z "MINU" ]; then
		usage
	fi
	if [ -z "$MAXU" ]; then
		usage
	fi
	if [ -z "$COUNT" ]; then
		usage
	fi

	shift $((OPTIND-1))
	CSDIR=$1

	if [ ! -d "$CSDIR" ]; then
		echo "Unreadable directory '$CSDIR'"
		exit -1
	fi


	cat <<EOF
Parameters: 
	Task Set Count: $COUNT
	Utilization min/max: $MINU/$MAXU
EOF
	run_tests
	return $?
}

function run_tests {
	echo "Performing Case Study Schedulability Analysis [$J]"
	local forked=0
	local spfx="Case Study Tests "
	local util
	for util in $(seq $MINU .1 $MAXU)
	do
		run_test $util &
		((forked++))
		add_status "$spfx" "+"
		if [ $forked -eq $J ] ; then
			wait -n
			if [ $? -ne 0 ] ; then
				echo "[$forked] process failed"
				exit -1
			fi
			((forked--))
			add_status "$spfx" "-"
		fi
	done
	# clean up the kids
	while [ $forked -gt 0 ] ; do
		wait -n
		if [ $? -ne 0 ]; then
			echo "Cleanup [$forked] process failed"
			exit -1
		fi
		((forked--))
		add_status "$spfx" '-'
	done
	add_status_newline
}

function run_test {
	local util=$1
	local count=0
	local wd=$(pwd)
	local result=${wd}/$(csname $util).sched

	pushd ${CSDIR} > /dev/null
	sched-test.sh -h > $result
	while [ $count -lt $COUNT ]
	do
		local name=$(csname $util $count).ts
		sched-test.sh -H $name >> $result
		((count++))
	done
	popd > /dev/null # ${CSDIR}

}

main "$@"
exit $?


