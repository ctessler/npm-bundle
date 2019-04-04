#!/bin/bash
# (setq sh-indentation 8)
# (setq sh-basic-offset 8)

# J limits the number of jobs that this will fork. It can be set by
# the user in their environment and is hidden with good purpose. This
# script is a fork-bomb a machine.
J=${J:-5}

# Taken from sched-test.sh, should probably be broken into a separate
# .sh library 
vfmt="%-28s%-6s%-6s%-6s%-6s%-6s\n"
rfmt="%-28s%-6.3f%-6.3f%-6.3f%-6.3f%-6.3f\n"

#
# Usage
#
function usage {
	b="`basename $0`"
	cat <<EOF
$b: For a particular data file, display the number of schedulable 
task sets for a specific (M, U, F) combination.

$b [OPTIONS] <FILE>
OPTIONS: 
	-h/--help			This message	
	-o/--output <FILE>		Output (defaults to STDOUT)

FILE:
	A .dat file generated from sched-sets.sh. 

EXAMPLE:
	$b -o M100m32U0.9F0.5.ratio M100m32U0.9F0.5.dat
EOF
	exit 1
}

function main {
	# false entry point
	#
	# Handle those arguments
	#
	short_opts="h:o:"
	long_opts="help,output:"

	args=`getopt -o ${short_opts} -l ${long_opts} -- "$@"`

	eval set -- ${args}
	while true ; do
		case "$1" in
			--help) ;&
			-h)
				usage
				return 0
				;;
			--output) ;&
			-o)
				output=$2 ; shift 2
				;;
			--)
				shift ; break
				;;
		esac
	done

	shift $((OPTIND-1))
	data=$1

	if [ ! -r "$data" ]; then
		echo "Unable to read data file '$data'"
		usage
		return -1
	fi

	if [ -n "$output" ]; then
		exec > $output
	fi

	local header=0
	while read -r line || [[ -n "$line" ]] ; do
		local arr=($line)
		arr=("${arr[@]:1}")
		if [ $header -lt 1 ] ; then
			local name=$(basename $data)
			name="#$name"
			print_header $name ${arr[@]}
			((header++))

			# Turn each of the fields into a value
			fields=($line)
			# Remove the name
			fields=("${fields[@]:1}")
			# Initialize the values to zero
			yes=("${fields[@]/*/0}")
			no=("${fields[@]/*/0}")
			err=("${fields[@]/*/0}")			
			continue
		fi

		# Count the no's and yes'.
		local i=0
		while [ $i -lt ${#arr[@]} ] ; do
			case ${arr[$i]} in
				Y) ((yes[i]++)) ;;
				N) ((no[i]++)) ;;
				*)
					echo "Malformed line $line" >&2;
					return -1
					;;
			esac
			((i++))
		done
	done < $data

	# Calculate the percentages
	local i=0
	while [ $i -lt ${#yes[@]} ]; do
		local y=${yes[$i]}
		local n=${no[$i]}
		pct=$(echo "$y / ($y + $n)" | bc -l)
		ratio[$i]="$pct"
		((i++))
	done


	print_header 'SCHEDULABLE' ${yes[@]}
	print_header 'UNSCHEDULABLE' ${no[@]}
	print_ratio 'RATIO' ${ratio[@]}

	return 0;
}

function print_header {
	printf $vfmt $@
}

function print_ratio {
	printf $rfmt $@
}

main "$@"
exit $?


