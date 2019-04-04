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
tmplt=${cfgdir}/alg-Mm-UxFxS.p
#
# Usage
#
function usage {
	b="`basename $0`"
	cat <<EOF
Generates the gnuplot files for comparing schedulability between 
algorithms in a 3D plot

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
	local spfx="Producing (M,M)x(U,F,S) Plots [$J] "
	add_status "$spfx"
	local forked=0
	for totm in ${M[*]}
	do
		tpj=${m[0]}
		m=("${m[@]:1}")

		# For a fixed (M,M)
		local name=$(gname $totm $tpj)

		tmplt_fill $tmplt $name

		local plotname=$(plot_file $name)
		gnuplot $plotname

		local tex=$(tex_file $name)
		topdf $tex &
		((forked++))
		add_status "$spfx" '+'
		if [ $forked -eq $J ] ; then
			# Going to keep the queue full
			wait -n
			if [ $? -ne 0 ]; then
				echo "[$forked] a epstopdf failed"
				exit -1
			fi
			((forked--))
			add_status "$spfx" '-'
		fi
	done
	# Clean up kids
	while [ $forked -gt 0 ] ; do
		wait -n
		if [ $? -ne 0 ]; then
			echo "Cleanup [$forked] a test failed"
			exit -1
		fi
		((forked--))
		add_status "$spfx" '-'
	done
	echo " done"
	add_status_newline
	return 0
}

function tex_file {
	local plotname=$1; shift;
	local strip=${plotname/.p/}
	printf "%s.tex" "$strip"
}

function plot_file {
	local name=$1 ; shift;
	printf "%s.p" "$name"
}

function tex_file {
	local name=$1 ; shift
	printf "%s.tex" "$name"
}

function tmplt_fill {
	local tmplt=$1 ; shift
	local name=$1 ; shift

	local plotf=$(plot_file $name)
	local tex=$(tex_file $name)
	cp $tmplt $plotf
	cat >> $plotf <<EOF
set output "$tex"
set title '\${(M=$totm, m=$tpj)}\$ Schedulability Ratio'

splot \\
EOF
	local i=0
	for s in ${sched_names[@]}; do
		local title=${sched_title[i]}
		((i++))
		local lines="lines";
		cat >> $plotf <<EOF
"$ratiodir/${name}-${s}.data" using 1:2:3 title "$title" with lines linetype $i, \\
EOF
		break
	done
}


main "$@"
exit $?


