#
# Descriptive name from
# gname $TOTAL_THREADS $MAX_TPJ $UTIL $GROWTH_FACTOR
#
# Usage:
#	name=$(gname $M $m $U $F)
#
function gname {
	local totm=$1
	local tpj=$2
	local util=$3
	local factor=$4

	if [ -n "$factor" ] ; then
		printf "M%03dm%02dU%.1fF%.1f" "$totm" "$tpj" "$util" "$factor"
		return 0
	fi

	if [ -n "$util" ] ; then
		printf "M%03dm%02dU%.1f" "$totm" "$tpj" "$util"
		return 0
	fi
	if [ -n "$tpj" ] ; then
		printf "M%03dm%02d" "$totm" "$tpj"
		return 0
	fi

	if [ -n "$totm" ] ; then
		printf "M%03dm%02d" "$totm"
		return 0
	fi
	return -1;
}

#
# Descriptive name for CASE STUDY task sets
#
# Usage
#	name=$(csname $utilization $number)
#
function csname {
	local u=$1
	local n=$2

	if [ -n "$n" ] ; then
		printf "CSU%.1f-%04d" "$u" "$n"
		return 0
	fi
	printf "CSU%.1f" "$u"
	
}



#
# Schedulability analysis names
#
sched_names=("LP-1 LP-M TPJ-i NP-1 NP-m")
read -r -a sched_names <<< "LP-1 LP-M TPJ-i NP-1 NP-m"
sched_title=("EDF-P:1 EDF-P:M EDF-TPJ EDF-NP:1 EDF-NP:M")
read -r -a sched_title <<< "EDF-P:1 EDF-P:M EDF-TPJ EDF-NP:1 EDF-NP:M"

function title_of_name {
	local name=$1 ; shift
	local i=0
	for p in ${sched_names[@]}; do
		if [ "$p" == "$name" ] ; then
			break
		fi
		((i++))
	done
	echo ${sched_title[i]}
}
		
#
# Printing format(s)
#
# Generic format
vfmt="%-28s%-6s%-6s%-6s%-6s%-6s\n"
rfmt="%-28s%-6.3f%-6.3f%-6.3f%-6.3f%-6.3f\n"

#
# Row of a schedulability ratio data file
#    ratio_row $file $U $F $S
function ratio_row {
	local file=$1 ; shift
	local U=$1 ; shift
	local F=$1 ; shift
	local S=$1 ; shift

	printf "%-6.3f%-6.3f%-6.3f\n" "$U" "$F" "$S" >> $file
}

# Header of a schedulability ratio data file
# 	ratio_header $file
function ratio_header {
	local ofile=$1 ; shift
	printf "#%-5s%-6s%-6s\n" "U" "F" "S" >> $ofile
}

#
# Shared status message display
#
# add_status $prefix $msg
#
status_len=0
status_max=75
function add_status {
	local status_pfx=""
	local msg=""
	status_pfx=$1 ; shift
	msg=$1 ; shift
	local total_len=0;
	((total_len = status_len + ${#msg}))
	if [ $total_len -ge $status_max ] ; then
		status_len=0
		echo ""
	fi
	if [ $status_len -eq 0 ] ; then
		echo -n "$status_pfx"
		status_len=${#status_pfx}
	fi
	echo -n "$msg"
	((status_len+=${#msg}))
}

function add_status_newline {
	echo ""
	status_len=0
}

#
# Converts a tex file into a pdf file
#
function topdf {
	local texname=$1 ; shift

	pdflatex $texname > /dev/null
	if [ $? -ne 0 ] ; then
		echo "Could not generate pdf from $texname"
		exit -1
	fi
}

#
# Create a sample PDF when using gnuplot -> latex
#
function sample {
	local texname=$1 ; shift
	local samplename=${texname/.tex/-sample.tex}

	cat >> $samplename <<EOF
\documentclass{article}
\usepackage{graphicx}
\begin{document}
\input{$texname}
\end{document}
EOF
	pdflatex $samplename >/dev/null
	if [ $? -ne 0 ] ; then
		echo "Could not generate pdf from $samplename"
		exit -1
	fi
}
