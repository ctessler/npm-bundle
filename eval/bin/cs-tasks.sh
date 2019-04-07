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

HDRFMT="%-18s%-8s%-12s%-16s\n"
BDYFMT="%-19s%-8d%-12d%-16d\n"
#
# Usage
#
function usage {
	b="`basename $0`"
	cat <<EOF
Generates the task sets of the case study based upon the BUNDLEP task set.

$b [OPTIONS] 
OPTIONS: *ALL* options are required and 
	-b/--base <FILE>		Template file
	-c/--count <INT>		Number of task sets per utilization
	-u/--min-util <FLOAT>		Utilizations min.
	-U/--max-util <FLOAT>		Utilizations max.
	-M/--total-threads <INT>	Total number of threads
	--min-tpj <INT>			Minimum threads per job
	--max-tpj <INT>			Maximum threads per job
	-s <FILE>			Path to the BUNDLE task set description
	-w <INT>			Scales WCET values from 1 to <INT>

EXAMPLE:
	$b -c 1000 -u .1 -U .9 -M 100 --min-tpj 2 --max-tpj 16 \\
	   -w 500 -s ../../cfg/bundlep.ts
EOF
	exit 1
}

# Artificial entry point
function main {
	#
	# Handle those arguments
	#
	short_opts="b:c:d:hu:U:M:s:"
	long_opts="base:count:,help,min-util:,max-util:,min-tpj:,max-tpj:"

	args=`getopt -o ${short_opts} -l ${long_opts} -- "$@"`

	eval set -- ${args}
	while true ; do
		case "$1" in
			--base) ;& # fall through
			-b)
				BASE=$2 ; shift 2
				;;
			--count) ;&
			-c)
				COUNT=$2; shift 2
				;;
			--wcet-scale) ;&
			-w)
				WCET_SCALE=$2; shift 2
				;;
			--help) ;&
			-h)
				usage
				return 0
				;;
			--min-util) ;&
			-u)
				u=$2 ; shift 2
				;;
			--max-util) ;&
			-U)
				U=$2 ; shift 2
				;;
			--min-tpj)
				MINTPJ=$2 ; shift 2
				;;
			--max-tpj)
				MAXTPJ=$2 ; shift 2
				;;
			--total-threads) ;&
			-M)
				M=$2 ; shift 2
				;;
			-s)
				TASKSET=$2 ; shift 2
				;;
			--)
				shift ; break
				;;
		esac
	done

	if [ -z "u" ]; then
		usage
	fi
	if [ -z "$U" ]; then
		usage
	fi
	if [ -z "$COUNT" ]; then
		usage;
	fi
	if [ -z "$TASKSET" ]; then
		usage
	fi
	if [ ! -e "$TASKSET" ]; then
		echo "Base task set file $TASKSET does not exist"
		usage
	fi
	if [ -z "$BASE" ] ; then
		usage
	fi
	if [ ! -e "$BASE" ]; then
		echo "Base template file $TASKSET does not exist"
		usage
	fi
	

	cat <<EOF
Parameters: 
	Task Set Template: $TASKSET
	Task Set Count: $COUNT
	Utilization min/max: $u/$U
EOF
	gen_tasks
	return $?
}

function gen_tasks {
	echo "Producing Case Study Task Sets [J]"
	local spfx="Case Study Tasks "
	local forked=0
	GSL_RNG_SEED=`date +%s`
	
	for util in $(seq $u .1 $U)
	do
		local count=0
		while [ $count -lt $COUNT ]
		do
			local name=$(csname $util $count)
			name="$name.ts"
			export GSL_RNG_SEED
			((GSL_RNG_SEED++))
			local cmd="ts-gentp-forwcet -s $TASKSET -p $BASE \
			    -U $util -o $name"
			$cmd &
			((count++))
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
	done
	return 0
		      
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

main "$@"
exit $?


