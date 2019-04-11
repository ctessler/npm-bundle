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
Generates a table of S values

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
	Must be a directory containing .count and .agg files produced by
	over-one.sh

EXAMPLE:
	$b -M "3, 5" -m "2, 2" -f .1 -F .9 -u .1 -U .9 -S 10 \\
	    -b base.tp over-one/
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
	aggdir=$1

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

	if [ ! -d "$aggdir" ]; then
		echo "Unreadable directory '$aggdir'"
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

	make_table
	return $?
}

function make_table {
	echo "Producing S Table "

	cat > by-m.tex <<EOF
  \begin{tabular}{|c|c|c|c|}
    \hline
    \${(M,m)}\$ & \${|S|}\$ & \${|s|}\$ & \${|\stpj{}|}\$ \\\\
    \hline
    \hline
EOF
	for totm in ${M[*]}
	do
		tpj=${m[0]}
		m=("${m[@]:1}")

		# For a fixed (M,M)
		local name=$(gname $totm $tpj)
		local aggf="$aggdir/$name.agg"

		local vals=( $( ext_vals $aggf) )
		local ts_total=${vals[0]}
		local oo_total=${vals[1]}
		local tpj_total=${vals[2]}
		local oo_ratio=${vals[3]}
		local tpj_ratio=${vals[4]}		
		cat >> by-m.tex <<EOF
      \${($totm, $tpj)}\$ & $ts_total & $oo_total & $tpj_total \\\\
      \hline
EOF
	done

	local totf="${aggdir}/OVER_ONE.agg"
	vals=( $( agg_vals $totf) )

	ts_total=${vals[0]}
	oo_total=${vals[1]}
	tpj_total=${vals[2]}
	oo_ratio=${vals[3]}
	tpj_ratio=${vals[4]}

	
	cat >> by-m.tex <<EOF
    \hline
    Total & $ts_total & $oo_total & $tpj_total \\\\
    \hline	  	
  \end{tabular}
  \caption{\${U > 1}\$ Feasibility}
  \label{table:by-m}
EOF
	cat > over-one.tex <<EOF
% Total number of task sets
\renewcommand{\totalTaskSets}{$ts_total}
% Total number of task sets when \tau^1 utilization > 1
\renewcommand{\totalOverOne}{$oo_total}
% Total number of OverOne task sets TPJ could schedule
\renewcommand{\totalOOTPJ}{$tpj_total}
% OverOne Ratio
\renewcommand{\ratioOverOne}{$oo_ratio}
% TPJ ratio
\renewcommand{\ratioOOTPJ}{$tpj_ratio}
EOF
	
	add_status_newline
	return 0
}

function agg_vals {
	local fname=$1 ; shift

	local ts_total=$(grep -v \# $fname | awk '{print $3}')
	local oo_total=$(grep -v \# $fname | awk '{print $4}')
	local tpj_total=$(grep -v \# $fname | awk '{print $5}')
	local oo_ratio=$(printf "%.4f" $( echo "$oo_total / $ts_total" | bc -l ) )
	local tpj_ratio=0
	if [ $oo_total -ne 0 ] ; then
		tpj_ratio=$(printf "%.4f" $( echo "$tpj_total / $oo_total" | bc -l ) )
	fi

	echo $ts_total $oo_total $tpj_total $oo_ratio $tpj_ratio
}

function ext_vals {
	local fname=$1 ; shift

	local ts_total=$(grep -v \# $fname | awk '{print $2}')
	local oo_total=$(grep -v \# $fname | awk '{print $3}')
	local tpj_total=$(grep -v \# $fname | awk '{print $4}')
	local oo_ratio=$(printf "%.4f" $( echo "$oo_total / $ts_total" | bc -l ) )
	local tpj_ratio=0
	if [ $oo_total -ne 0 ] ; then
		tpj_ratio=$(printf "%.4f" $( echo "$tpj_total / $oo_total" | bc -l ) )
	fi

	echo $ts_total $oo_total $tpj_total $oo_ratio $tpj_ratio
}

main "$@"
exit $?


