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

# Configuration directory, need this to find the plot template
cfgdir=${contdir}/../cfg/
tmplt=${cfgdir}/2D-MmUFxS.p


#
# Usage
#
function usage {
	b="`basename $0`"
	cat <<EOF
Generates the gnuplot files for comparing schedulability between 
algorithms in a 2D plot

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
	Must be a directory containing .data files produced by
	ratio-by-alg.sh

EXAMPLE:
	$b -M "3, 5" -m "2, 2" -f .1 -F .9 -u .1 -U .9 -S 10 \\
	    -b base.tp ratio-by-alg/
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
	ratio_dir=$1

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

	if [ ! -d "$ratio_dir" ]; then
		echo "Unreadable directory '$avg_ratio_dir'"
		return -1
	fi

	if [ ! -e "$tmplt" ] ; then
		echo "Could not find template '$tmplt'"
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

	produce_plots
	return $?
}

function produce_plots {
	echo "Producing (M,M,[U,F])x(S) Plots [$J] "
	local spfx="(M,M,[U,F])x(S) "
	add_status "$spfx"
	local forked=0
	for totm in ${M[*]}
	do
		tpj=${m[0]}
		m=("${m[@]:1}")

		# For a fixed (M,M)
		local name=$(gname $totm $tpj)

		for util in $(seq $u .1 $U) ; do
			local uname=$(printf "%sU%.1f" $name $util)
			tmplt_fill $uname 'U' $util
			gnuplot $(plot_file $uname 'U') 

			topdf $(tex_file $uname 'U') &
			((forked++))
			add_status "$spfx" '+'
			if [ $forked -eq $J ] ; then
				# Going to keep the queue full
				wait -n
				if [ $? -ne 0 ]; then
					echo "[$forked] util pdf failed"
					exit -1
				fi
				((forked--))
				add_status "$spfx" '-'
			fi
		done
		while [ $forked -gt 0 ] ; do
			wait -n
			if [ $? -ne 0 ]; then
				echo "Cleanup [$forked] util pdf failed"
				exit -1
			fi
			((forked--))
			add_status "$spfx" '-'
		done

		for factor in $(seq $f .1 $F) ; do
			local fname=$(printf "%sF%.1f" $name $factor)
			tmplt_fill $fname 'F' $factor
			gnuplot $(plot_file $fname 'F') 

			topdf $(tex_file $fname 'F') &
			((forked++))
			add_status "$spfx" '+'
			if [ $forked -eq $J ] ; then
				# Going to keep the queue full
				wait -n
				if [ $? -ne 0 ]; then
					echo "[$forked] factor pdf failed"
					exit -1
				fi
				((forked--))
				add_status "$spfx" '-'
			fi
		done
		while [ $forked -gt 0 ] ; do
			wait -n
			if [ $? -ne 0 ]; then
				echo "Cleanup [$forked] factor topdf failed"
				exit -1
			fi
			((forked--))
			add_status "$spfx" '-'
		done
		
	done
	add_status "$spfx" " done"
	add_status_newline
	return 0
}

function tex_file {
	local name=$1; shift;
	local dim=$1; shift
	local rep=$(echo $name | sed 's/\./_/')
	printf "2D-%sxS.tex" "$rep"
}

function eps_file {
	local name=$1; shift;
	local dim=$1; shift
	local rep=$(echo $name | sed 's/\./_/')
	printf "2D-%sxS.eps" "$rep"
}

function data_file {
	local name=$1 ; shift
	local sched=$1 ; shift
	printf "%s/%s-%s.data" "$ratio_dir" "$name" "$sched"
}

function plot_file {
	local name=$1 ; shift
	local dim=$1 ; shift
	printf "2D-%sxS.p" "$name"
}

function tmplt_fill {
	local name=$1 ; shift
	local dim=$1 ; shift
	local dimv=$1 ; shift

	local texf=$(tex_file $name $dim)
	local epsf=$(eps_file $name $dim)
	local plotf=$(plot_file $name $dim)
	local xlabel="Growth Factor";
	if [ $dim == 'F' ] ; then
		xlabel="Utilization"
	fi

	cp $tmplt $plotf
	if [ $? -ne 0 ] ; then
		echo "Could not copy $tmplt to $plotf"
		exit -1
	fi
	cat >> $plotf <<EOF
set xlabel "$xlabel"
set output "$texf"

set title 'Schedulability Ratio for \${(M=$totm,m \\le $tpj, $dim=$dimv)}\$'

plot \\
EOF
	for sched in ${sched_names[@]}; do
		((i++)) 
		local dataf=$(data_file $name $sched)
		local title=$(title_of_name $sched)
		cat >> $plotf <<EOF
"$dataf" using 1:2 title "$title" with linespoints, \\
EOF
	done
}

main "$@"
exit $?


