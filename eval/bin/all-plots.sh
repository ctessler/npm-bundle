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
Generates a PDF of all of the available plots

$b [OPTIONS] 
OPTIONS: No options

DIRECTORY:
	Must be run from within the "plot/" directory, when run
	outside of such a directory the results are unknown and
	unsafe. 
EOF
	exit 1
}

FINDCMD="find . -type f \( -name \"*.pdf\" -and ! -name \"*-eps-converted-to.pdf\" \)"
# False entrypoint
function main {
	local cmd="$FINDCMD | sort -n"

	cat > all-plots.tex <<EOF
\documentclass[a4paper]{article}
\usepackage{geometry}
\geometry{legalpaper, margin=1in}
\usepackage{subcaption}
\usepackage{graphicx}

\begin{document}
EOF
	local odd=0
	local count=0
	for file in $(eval $cmd)
	do
		if [ $odd -eq 0 ] ; then
			cat >> all-plots.tex <<EOF
\begin{figure}
EOF
		fi
		local printable=${file/_/\\_}
		cat >> all-plots.tex <<EOF
  \begin{subfigure}{.5\linewidth}
    \includegraphics[width=\linewidth]{$file}
    \caption{$printable}
  \end{subfigure}%
EOF
		if [ $odd -eq 1 ] ; then
			cat >> all-plots.tex <<EOF
\end{figure}
EOF
		fi
		((odd++))
		if [ $odd -eq 2 ] ; then
			odd=0
		fi
		((count++))
		if [ $count -eq 6 ] ; then
			cat >> all-plots.tex <<EOF
\clearpage
EOF
			count=0
		fi
	done
	if [ $odd -eq 1 ] ; then
		cat >> all-plots.tex <<EOF
\end{figure}
EOF
	fi
	cat >> all-plots.tex <<EOF
\end{document}
EOF
	
}

# Last command in the file.
main "$@"
exit $?

