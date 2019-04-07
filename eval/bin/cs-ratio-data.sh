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
Generates the schedulability ratio data for the aggregate of COUNT sets 
$b [OPTIONS] <DIRECTORY>
OPTIONS: *ALL* options are required and *must* match incip-sets.sh
	-c/--count <INT>		Tasks per configuration
	-u/--min-util <FLOAT>		Utilizations min.
	-U/--max-util <FLOAT>		Utilizations max.

DIRECTORY:
	Must be a directory containing .ts files produced by
	cs-sched-ratios.sh

EXAMPLE:
	$b -u .1 -U .9 -c 1000 ../cs-ratio
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
	compile
	return $?
}

function compile {
	echo "Compiling Case Study Schedulability Ratio Data [$J] -- unused"
	local forked=0
	local spfx="CS Compile "
	local util

	print_header "#UTIL" "LP-1" "LP-M" "TPJ-i" "NP-1" "NP-m" > cs-ratio.data
	for util in $(seq $MINU .1 $MAXU)
	do
		local name=$(csname $util).sched
		read_file ${CSDIR}/$name
		print_ratio "$util" "${sched[@]}" >> cs-ratio.data
		add_status "$spfx" "."		
	done
	add_status_newline	
}

#
# Will create two arrays :
#    ${alg[@]}
#    ${sched[@]}
#
# alg contains the name, sched contains the schedulability ratio
#
function read_file {
	local file=$1

	local count=0;
	while read -r line ; do
		# Header row
		if [ $count -eq 0 ]; then
			unset alg
			alg=($line)
			alg=("${alg[@]:1}")
		fi
		if [ $count -eq 3 ]; then
			unset sched
			sched=($line)
			sched=("${sched[@]:1}")
			break
		fi
		((count++))
	done < "$file"

	return 0
}

function print_header {
	printf $vfmt $@
}

function print_ratio {
	printf $rfmt $@
}


main "$@"
exit $?


