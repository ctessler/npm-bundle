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
Generates an incipient task sets
$b [OPTIONS]
OPTIONS: *ALL* options are required
	-M/--total-threads <LIST>	Total threads in the task set
	-m/--max-tpj <LIST>		Max. threads per job (tied to M)
	-u/--min-util <FLOAT>		Utilizations min.
	-U/--max-util <FLOAT>		Utilizations max.
	-F/--max-factor <FLOAT>		Growth factor min.
	-f/--min-factor <FLOAT>		Growth factor max.
	-S/--sets <INT>			Sets per (M,U,F)
	-b/--base <FILE>		Base template
EXAMPLE:
	$b -M "3, 5" -m "2, 2" -f .1 -F .9 -u .1 -U .9 -S 10 -b base.tp
EOF
	exit 1
}

#
# Handle those arguments
#
short_opts="b:f:u:m:n:F:U:M:S:"
long_opts="base:,min-factor:,min-util:,max-tpj:,name:,max-factor:,max-util:,total-threads:,sets:"

args=`getopt -o ${short_opts} -l ${long_opts} -- "$@"`

eval set -- ${args}
while true ; do
	case "$1" in
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

function gname {
	printf "M%03dm%02dU%.1fF%.1f" "$totm" "$tpj" "$util" "$factor"
}



function forkedrun {
	# Need $S tasksets in the set
	local idx=1 s=1
	GSL_RNG_SEED=`date +%s`
	while [ $s -le $S ]; do
		export GSL_RNG_SEED
		((GSL_RNG_SEED++))
		local num=$(printf "%04d" $s)
		ts-gentp -p $base --total-threads $totm -o ${name}-${num}.ts \
			 --max-tpj $tpj --max-factor $factor --util $util &
		((forked++))
		add_status "$SPFX" '+'
		if [ $forked -eq $J ] ; then
			# keep the queue full
			wait -n
			if [ $? -ne 0 ]; then
				echo "[$forked] a child failed"
				exit -1
			fi
			((forked--))
			add_status "$SPFX" '-'
		fi
		((s++))
	done
}

echo "Generating task sets [$J]"
export GSL_RNG_TYPE=ranlxs2
forked=0
SPFX="Task set generation "
for totm in ${M[*]}
do
	tpj=${m[0]}
	m=("${m[@]:1}")
	for util in $(seq $u .1 $U); do
		for factor in $(seq $f .1 $F); do
			add_status "$SPFX"
			name=$(gname)
			forkedrun
		done
	done
done

# Wait for kids
while [ $forked -gt 0 ] ; do
	wait -n
	if [ $? -ne 0 ]; then
		echo "Cleanup [$forked] a test failed"
		exit -1
	fi
	((forked--))
	add_status "$SPFX" "-"
done

echo " done"

exit 0
