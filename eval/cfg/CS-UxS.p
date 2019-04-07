# -*- mode: gnuplot; -*-
#
# Template for generating 3D plots for one (M,m) of all algorithms.
#
#set terminal postscript eps enhanced color
set terminal epslatex standalone color
set termoption dashed

# LP-1
set linetype 1 linewidth 1 dashtype 2 linecolor "black" pointsize 0
# LP-M
set linetype 2 linewidth 2 linecolor "gray"
# TPJ-i
set linetype 3 linewidth 2 pointtype 6 linecolor 7
# NP-1
set linetype 4 
# NP-m
set linetype 5 pointtype 8 linecolor 6

set key opaque
set grid
set xrange [.05:1.05]
set yrange [-.05:1.05]

set ylabel "Schedulability Ratio" rotate parallel
set xlabel "Utilization"
set key outside
set output "cs-ratio.tex"

set title "BUNDLEP Case Study, BRT:100 CPI:1 Cache Lines:32"
 
plot \
"../../data/cs-ratio-data/cs-ratio.data" using 1:2 title "EDF-P:1" with linespoints, \
"../../data/cs-ratio-data/cs-ratio.data" using 1:3 title "EDF-P:M" with linespoints, \
"../../data/cs-ratio-data/cs-ratio.data" using 1:4 title "EDF-TPJ" with linespoints, \
"../../data/cs-ratio-data/cs-ratio.data" using 1:5 title "EDF-NP:1" with linespoints, \
"../../data/cs-ratio-data/cs-ratio.data" using 1:6 title "EDF-NP:M" with linespoints

# Nothing changes with the different runs.
