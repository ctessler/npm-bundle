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
	-M/--total-threads <LIST>	Total threads in the task set
	-m/--max-tpj <LIST>		Max. threads per job (tied to M)
	-u/--min-util <FLOAT>		Utilizations min.
	-U/--max-util <FLOAT>		Utilizations max.
	-F/--max-factor <FLOAT>		Growth factor min.
	-f/--min-factor <FLOAT>		Growth factor max.
	-S/--sets <INT>			Sets per (M,U,F)
	-b/--base <FILE>		Base template

DIRECTORY:
	Must be a directory containing .ts files produced by
	incip-sets.sh

EXAMPLE:
	$b -M "3, 5" -m "2, 2" -f .1 -F .9 -u .1 -U .9 -S 10 \\
	    -b base.tp ts/
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

shift $((OPTIND-1))
tsdir=$1

if [ ! -d "$tsdir" ]; then
	echo "Unreadable directory '$tsdir'"
	exit -1
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

echo "Performing schedulability analysis [$J]"
forked=0
spfx="Schedulability tests "
for totm in ${M[*]}
do
	tpj=${m[0]}
	m=("${m[@]:1}")

	for util in $(seq $u .1 $U); do
		for factor in $(seq $f .1 $F); do
			add_status "$spfx"
			name=$(gname $totm $tpj $util $factor)
			sched-part.sh ${tsdir}/${name} $S &
			((forked++))
			add_status "$spfx" '+'
			
			if [ $forked -eq $J ] ; then
				# Going to keep the queue full
				wait -n
				if [ $? -ne 0 ]; then
					echo "[$forked] a test failed"
					exit -1
				fi
				((forked--))
				add_status "$spfx" '-'
			fi
		done
	done
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

exit 0

# ----------------------------------------------------------------------
# Alternative version using a temporary file
# ----------------------------------------------------------------------

echo -n "Creating schedulability parameter list"
file="sched-commands.sh"
rm -f $file
for totm in ${M[*]}
do
	tpj=${m[0]}
	m=("${m[@]:1}")
	for util in $(seq $u .1 $U); do
		for factor in $(seq $f .1 $F); do
			name=$(gname)
			echo sched-part.sh ${name} $S >> $file
		done
	done
done


forked=0
count=0
while read -r cmd || [[ -n "$cmd" ]] ; do
	count=$(( count % 65 ))
	if (( count == 0 )) ; then
		echo "" ; echo -n "Schedulability ."
	else
		echo -n "."
	fi
	((count++))

	$cmd &
	((forked++))
	
	if [ $forked -eq $J ] ; then
		wait -n
		if [ $? -ne 0 ]; then
			echo "[$forked] a test failed"
			exit -1
		fi
		((forked--))
	fi
done < "$file"

echo " done"
exit 0
