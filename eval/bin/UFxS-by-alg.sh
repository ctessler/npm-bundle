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
Generates the schedulability ratio data for a specific algorithm, for
for (M,m,U) and (M,m,F) values.

$b [OPTIONS] <DIRECTORY>
OPTIONS: *ALL* options are required and *must* match incip-sets.sh
	-M/--total-threads <LIST>	Total threads in the task set
	-m/--max-tpj <LIST>		Max. threads per job (tied to M)
	-u/--min-util <FLOAT>		Utilizations min.
	-U/--max-util <FLOAT>		Utilizations max.
	-F/--max-factor <FLOAT>		Growth factor min.
	-f/--min-factor <FLOAT>		Growth factor max.
	-S/--sets <INT>			Sets per (M,U,F)
	-b/--base <FILE>		Base template

DIRECTORY:
	Must be a directory containing .sched files produced by
	ratio-by-alg.sh.

EXAMPLE:
	$b -M "3, 5" -m "2, 2" -f .1 -F .9 -u .1 -U .9 -S 10 \\
	    -b base.tp ratio/
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
	ratiodir=$1

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

	if [ ! -d "$ratiodir" ]; then
		echo "Unreadable directory '$ratiodir'"
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

	calc_ratios
	return $?
}

function calc_ratios {
	echo "Producing (M,M,[U,F])x(S) Ratios [$J] "	
	local spfx="(M,M,[U,F])x(S) "
	local forked=0
	for totm in ${M[*]}
	do
		tpj=${m[0]}
		m=("${m[@]:1}")

		# For a fixed (M,M)
		local name=$(gname $totm $tpj)
		for sched in ${sched_names[@]} ; do
			local dataf=${ratiodir}/${name}-${sched}.data
			add_status "$spfx" "."
			for util in $(seq $u .1 $U) ; do
				local oname=$(gname $totm $tpj)
				oname=$(printf "%sU%.1f" "$oname" "$util")-${sched}.data
				local gtoken=$(printf "^%0.3f" $util)
				echo "#U=$util from $dataf" > $oname
				printf "%-6s%-6s\n" "#F" "S" >> $oname
				grep $gtoken $dataf > ${oname}.awk
				awk '{printf "%-6s%-6s\n", $2, $3}' ${oname}.awk \
				    >> $oname
				rm ${oname}.awk
			done
			add_status "$spfx" "."			
			for factor in $(seq $f .1 $F) ; do
				local oname=$(gname $totm $tpj)
				oname=$(printf "%sF%.1f" "$oname" "$factor")-${sched}.data
				awk 'NR > 1 {printf "%-6s%-6s%-6s\n", $2, $1, $3}' \
				    ${dataf} > ${oname}.grep
				# F U S -- now
				local gtoken=$(printf "^%0.3f" $factor)
				echo "#F=$factor from $dataf" > $oname
				printf "%-6s%-6s\n" "#U" "S" >> $oname
				grep $gtoken ${oname}.grep > ${oname}.awk
				awk '{printf "%-6s%-6s\n", $2, $3}' ${oname}.awk \
				    >> $oname
				rm ${oname}.awk
				rm ${oname}.grep
			done
		done
	done
	add_status "$spfx" " done"
	add_status_newline
	return 0
}

function compile {
	local ifile=$1 ; shift
	local ofile=$1 ; shift

	rm -f $ofile
	ratio_header $ofile
	local skip=1
	while read -r line || [[ -n "$line" ]] ; do
		if [ $skip -eq 1 ] ; then
			skip=0
			continue
		fi
		local array=($line)
		local count=0 U=0 F=0 S=0
		while [ $count -lt ${#array[@]} ] ; do
			U=${array[$count]}
			((count++))
			F=${array[$count]}
			((count++))
			S=$(echo "$S + ${array[$count]}" | bc -l)
			((count++))
		done
		local denom=$(echo "${#array[@]} / 3" | bc -l)
		local avg=$(echo "$S / $denom" | bc -l)
		avg=$(printf "%0.3f" $avg)
		ratio_row $ofile $U $F $avg
	done < $ifile
	return 0
}

main "$@"
exit $?


