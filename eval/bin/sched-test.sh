#!/bin/bash

verbose=0
header=1

#
# Usage
#
function usage {
	base="`basename $0`"
	cat <<EOF
Determines if an incipient task set is schedulable by EDF, EDF-NP, 
and EDF-NP+TPJ
$base <FILE> [OPTIONS]
OPTIONS:
	<FILE>		Task set file (required)
	-H		Do *not* print the header row
	-h		Print only the header row	
	-k/--keep	Keep temporary files
	-v		Verbose output

OUTPUT:

	#name                       LP-1  LP-M  TPJ-i NP-1  NP-m
	ts/M003m02U0.1F0.1-0001.ts  Y     Y     N     Y     N
	^			    ^	  ^	^     ^	    ^
	|			    |	  |	|     |	    |
	Task set name		    |	  |	|     |	    |
               Preemptive EDF (m=1)-+	  |	|     |	    |
	         Preemptive EDF (merged) -+     |     |	    |
 	     Nonpreemptive EDF Threads Per Job -+     |	    |
		             Nonpreemptive EDF (m=1) -+	    |
			        Nonpreemptive EDF (merged) -+
EOF
	exit 1
}

# verbose echo
function vecho {
	if [[ "$verbose" -ne "1" ]]; then
		return
	fi
	echo $@
}

# verbose command execution
function vcmd {
	if [[ "$verbose" -ne "1" ]]; then
		$@ > /dev/null
		rv=$?
		return $rv
	fi
	echo $@
	$@
	rv=$?
	return $rv
}

# Convert schedulability analysis results to Y or N
function schedyn {
	if [[ $1 -eq 0 ]]; then
		echo Y
		return
	fi
	if [[ $1 -eq 1 ]]; then
		echo N
		return
	fi
	echo E # error!
	return
}

#
# Handle those arguments
#
short_opts="hHkv"
long_opts="keep"

args=`getopt -o ${short_opts} -l ${long_opts} -- "$@"`

if [ $? != 0 ] ; then
	usage
	exit 1
fi

eval set -- ${args}
while true ; do
	case "$1" in
		-H)
			header=0
			shift
			;;
		-h)
			header=2
			shift
			;;
		--keep)
			;& # fall through
		-k)
			keep=1
			shift
			;;
		-v)
			verbose=1
			shift
			;;
		--)
			shift
			break
			;;
	esac
done

shift $(($OPTIND -1 ))
file=$1;

hfmt="#%-27s%-6s%-6s%-6s%-6s%-6s\n"
vfmt="%-28s%-6s%-6s%-6s%-6s%-6s\n"

if [ "$header" -eq "2" ]; then
	printf "$hfmt" "name" "LP-1" "LP-M" "TPJ-i" "NP-1" "NP-m"
	exit 0;
fi

if [ -z "$file" ]; then
	usage
fi

divided=${file/.ts/.o.ts}
merged=${file/.ts/.m.ts}

if [ -e $divided ] ; then
	echo "Temporary file $divided exists, aborting!";
	exit 1;
fi

if [ -e $merged ] ; then
	echo "Temporary file $merged exists, aborting!";
	exit 1;
fi

#
# Create the divided task set
#
cmd="ts-divide --maxm 1 -s $file -o $divided"
vcmd $cmd
if [ $? -ne 0 ]; then
	echo "Could not divide task set, command:"
	echo "	$cmd"
	exit 1
fi

#
# Create the merged task set
#
cmd="ts-merge -s $file -o $merged"
vcmd $cmd
if [ $? -ne 0 ]; then
	echo "Could not merge task set, command:"
	echo "	$cmd"
	exit 1
fi

vecho "" ; vecho "TPJ incipient task set"
cmd="tpj -s $file"
vcmd $cmd
tpj_sched=$(schedyn $?)

vecho "" ; vecho "Maximum Chunks (m=1)"
cmd="maxchunks -s $divided -l ${divided}-p.log"
vcmd $cmd
mc_sched_lp=$(schedyn $?)
rm ${divided}-p.log

vecho "" ; vecho "Maximum Chunks (m=1) Non-Preemptive"
cmd="maxchunks --nonp -s $divided -l ${divided}-np.log"
vcmd $cmd
mc_sched_np=$(schedyn $?)
rm ${divided}-np.log

vecho "" ; vecho "Maximum Chunks (merged) Non-Preemptive"
cmd="maxchunks --nonp -s $merged -l ${merged}-np.log"
vcmd $cmd
mc_sched_merge=$(schedyn $?)
rm ${merged}-np.log

vecho "" ; vecho "Maximum Chunks (merged) Preemptive"
cmd="maxchunks -s $merged -l ${merged}-p.log"
vcmd $cmd
mc_sched_lp_merge=$(schedyn $?)
rm ${merged}-p.log

vecho "" 
if [ "$header" -eq "1" ]; then
	printf "$hfmt" "name" "LP-1" "LP-M" "TPJ-i" "NP-1" "NP-m"
fi
printf "$vfmt" $file $mc_sched_lp $mc_sched_lp_merge $tpj_sched $mc_sched_np $mc_sched_merge

#
# Remove temporary files
#
if [ -z "$keep" ] ; then
	vcmd rm $merged $divided
fi

SUCCESS=0
for v in $mc_sched_lp $mc_sched_lp_merge $tpj_sched $mc_sched_np $mc_sched_merge
do
	case $v in
		Y) ;&
		N)
			break
			;;
		*)
			SUCCESS=-1
	esac
done			
	
exit $SUCCESS
