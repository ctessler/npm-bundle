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
set linetype 3 linewidth 1 pointtype 6 linecolor 7
# NP-1
set linetype 4 
# NP-m
set linetype 5 pointtype 8 linecolor 6

set key opaque
set grid
set xrange [-.05:1.05]
set yrange [-.05:1.05]

set ylabel "Schedulability Ratio" rotate parallel

# U	F	S

# set output "output.eps"
# set title "(M=3, m=2, Sched) Schedulability Ratio"

#
# splot "M003m02-LP-1.data" using 1:3 title "LP-1" with lines lt 1, \
# 	"M003m02-LP-M.data" using 1:3 title "LP-M" with lines lt 2, \
#       "M003m03-TPJ-i.data" using 1:3 title "TPJ-i" with lines lt 3
#


