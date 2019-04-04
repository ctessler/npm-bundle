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
Generates the table of information of the over one utilization task
sets found in the generated task sets.

For each (M,m,U,F), there will a portion of the task sets (when
reduced to one thread per job) will have utilization greater than
1.0; that number is s. The total number of task sets is S. The ratio
of s that TPJ can schedule is S^TPJ

$b [OPTIONS] <DIRECTORY> <DIRECTORY>
OPTIONS: *ALL* options are required and *must* match incip-sets.sh
	-M/--total-threads <LIST>	Total threads in the task set
	-m/--max-tpj <LIST>		Max. threads per job (tied to M)
	-u/--min-util <FLOAT>		Utilizations min.
	-U/--max-util <FLOAT>		Utilizations max.
	-F/--max-factor <FLOAT>		Growth factor min.
	-f/--min-factor <FLOAT>		Growth factor max.
	-S/--sets <INT>			Sets per (M,U,F)
	-b/--base <FILE>		Base template

DIRECTORY 1:
	Must be a directory containing .sched files produced by
	sched-test-sets.sh.

DIRECTORY 2:
	Must be a directory containing .ts files produced by
	incip-sets.sh.

EXAMPLE:
	$b -M "3, 5" -m "2, 2" -f .1 -F .9 -u .1 -U .9 -S 10 \\
	    -b base.tp ../sched/ ../ts/
EOF
	exit 1
}

# Artificial entry point
function main {
	#
	# Handle those arguments
	#
	short_opts="hb:f:u:m:n:F:U:M:S:"
	long_opts="help,base:,min-factor:,min-util:,max-tpj:,name:,max-factor:,"
	long_opts="${longopts}max-util:,total-threads:,sets:"

	args=`getopt -o ${short_opts} -l ${long_opts} -- "$@"`

	eval set -- ${args}
	while true ; do
		case "$1" in
			--help) ;&
			-h)
				usage
				return 0
				;;
			--base) ;& # fall through
			-b)
				base=$2 ; shift 2
				;;
			--min-factor) ;& # fall through
			-f)
				f=$2 ; shift 2
				;;
			--min-util) ;&
			-u)
				u=$2 ; shift 2
				;;
			--max-tpj) ;&
			-m)
				m=$2 ; shift 2
				;;
			--name) ;&
			-n)
				name=$2 ; shift 2
				;;
			--max-factor) ;&
			-F)
				F=$2 ; shift 2
				;;
			--max-util) ;&
			-U)
				U=$2 ; shift 2
				;;
			--total-threads) ;&
			-M)
				M=$2 ; shift 2
				;;
			--sets) ;&
			-S)
				S=$2 ; shift 2
				;;
			--)
				shift ; break
				;;
		esac
	done

	shift $((OPTIND - 1))
	scheddir=$1 ; shift
	tsdir=$1 ; shift

	if [ -z "$f" ]; then
		usage
	fi
	if [ -z "u" ]; then
		usage
	fi
	if [ -z "$m" ]; then
		usage
	fi
	if [ -z "$F" ]; then
		usage
	fi
	if [ -z "$U" ]; then
		usage
	fi
	if [ -z "$M" ]; then
		usage
	fi
	if [ -z "$S" ]; then
		usage
	fi
	if [ ! -e "$base" ]; then
		echo "Template file $base does not exist"
		usage
	fi

	if [ ! -d "$scheddir" ]; then
		echo "Unreadable directory '$scheddir'"
		return -1
	fi

	if [ ! -d "$tsdir" ]; then
		echo "Unreadable directory '$tsdir'"
		return -1
	fi

	cat <<EOF
Parameters: $base +
	(f,F) = ($f,$F)	(u,U) = ($u,$U)	|(M,U,F)| = $S
	(m,M) = ({$m},{$M})	
EOF

	# Turn the lists into elements
	oifs=$IFS
	IFS=', '
	read -r -a m <<< "$m"
	read -r -a M <<< "$M"
	IFS=$oifs

	over_ones
	return $?
}

function over_ones {
	echo "Producing Over One Ratios [$J] "	
	local spfx="Over One Collect "
	local forked=0
	local preserved=("${m[@]}")
	for totm in ${M[*]}
	do
		tpj=${m[0]}
		m=("${m[@]:1}")
		for util in $(seq $u .1 $U) ; do
			for factor in $(seq $f .1 $F) ; do
				local name=$(gname $totm $tpj $util $factor)
				process "$spfx" $name &
				((forked++))
				add_status "$spfx" "+"
				if [ $forked -eq $J ] ; then
					# keep the queue full
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
	done
	# Clean up kids
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

	spfx="Over One Aggregate "
	m=("${preserved[@]}")
	for totm in ${M[*]}
	do
		tpj=${m[0]}
		m=("${m[@]:1}")
		aggregate "$spfx" $totm $tpj &
		((forked++))
		add_status "$spfx" "+"
		if [ $forked -eq $J ] ; then
			# keep the queue full
			wait -n
			if [ $? -ne 0 ] ; then
				echo "[$forked] aggregate failed"
				exit -1
			fi
			((forked--))
			add_status "$spfx" "-"
		fi		
	done
	# Clean up kids
	while [ $forked -gt 0 ] ; do
		wait -n
		if [ $? -ne 0 ]; then
			echo "Cleanup [$forked] aggregate failed"
			exit -1
		fi
		((forked--))
		add_status "$spfx" '-'
	done

	# Time to get gross
	rm -f OVER_ONE.agg
	local total_ts=$(cat *.agg | grep -v \# | awk '{sum+=$2} END {print sum;}')
	local total_oo=$(cat *.agg | grep -v \# | awk '{sum+=$3} END {print sum;}')
	local total_tpj=$(cat *.agg | grep -v \# | awk '{sum+=$4} END {print sum;}')

	printf $HDRFMT "#NAME" "|TASKS|" "|OVER ONE|" \
	       "|OVER ONE & TPJ FEAS|" > OVER_ONE.agg
	printf $BDYFMT "ALL SETS" $total_ts $total_oo $total_tpj >> OVER_ONE.agg
	
	add_status "$spfx" " done see OVER_ONE.agg and *.agg files"
	add_status_newline
	
	return 0
}

function process {
	local spfx=$1 ; shift
	local name=$1 ; shift
	local dataf=$(sched_file $name)
	
	if [ ! -f $dataf ] ; then
		add_status "$spfx" "could not find data file $dataf"
		return -1
	fi
	
	local taskset lp1 lpm tpj np1 npm
	local ts_count=0
	local oo_count=0;
	local oo_tpj_feas=0
	while read -r taskset lp1 lpm tpj np1 npm
	do
		if [ $taskset == "#name" ]; then
			continue;
		fi
		((ts_count++))
		tasknumber=$(echo $taskset | sed s/.*-// | sed s/\.ts//)
		if [ $lp1 != "N" ]; then
			# If EDF-P:1 could schedule it, U < 1
			continue;
		fi

		local outil=$(one_util $taskset)
		if (( $(echo "$outil <= 1.0" | bc -l) )) ; then
			# Utilization is below 1.0, just infeasible
			continue;
		fi
		((oo_count++))

		if [ $tpj == "Y" ]; then
			((oo_tpj_feas++))
		fi
	done < $dataf
	local countf=$(count_file $name)
	printf $HDRFMT "#NAME" "|TASKS|" "|OVER ONE|" \
	       "|OVER ONE & TPJ FEAS|" > $countf
	printf $BDYFMT "$name" $ts_count $oo_count $oo_tpj_feas	>> $countf
	return 0;
}

function sched_file {
	local name=$1 ; shift
	printf "%s/%s.sched" $scheddir $name
}

function ts_file {
	local name=$1 ; shift
	printf "%s/%s" $tsdir $name
}

function count_file {
	local name=$1 ; shift
	printf "%s.count" $name
}

function agg_file {
	local M=$1 ; shift
	local m=$1 ; shift
	local name=$(gname $M $m)

	printf "%s.agg" "$name"
}

#
# Divide the task set, and prints the single task utilization
#
function one_util {
	local taskset=$1 ; shift
	local tsf=$(ts_file $taskset)
	local div=${taskset/.ts/.o.ts}

	cmd="ts-divide --maxm 1 -s $tsf -o $div"
	$cmd
	if [ $? -ne 0 ]; then
		echo "Could not divide $div"
		exit -1
	fi

	ts-print -u $div
	rm $div
}

function aggregate {
	local spfx=$1 ; shift
	local M=$1 ; shift
	local m=$1 ; shift

	local total_ts total_oo total_tpjf
	total_ts=0
	total_oo=0
	total_tpjf=0
	for util in $(seq $u .1 $U) ; do
		for factor in $(seq $f .1 $F) ; do
			local name=$(gname $totm $tpj $util $factor)
			local countf=$(count_file $name)
			local first=1
			local decor ts_count oo_count oo_tpj_feas
			while read -r decor ts_count oo_count oo_tpj_feas
			do
				if [ $first -eq 1 ] ; then
					((first--))
					continue;
				fi
				((total_ts += ts_count))
				((total_oo += oo_count))
				((total_tpjf += oo_tpj_feas))
			done < $countf
		done
	done

	local aggf=$(agg_file $M $m)
	printf $HDRFMT "#NAME" "|TASKS|" "|OVER ONE|" \
	       "|OVER ONE & TPJ FEAS|" > $aggf
	printf $BDYFMT $(gname $M $m) $total_ts $total_oo $total_tpjf >> $aggf

}

main "$@"
exit $?


