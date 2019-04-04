# -*- mode: gnuplot; -*-
#
# Template for generating 3D plots for one (M,m) of all algorithms.
#
#set terminal postscript eps enhanced color
set terminal epslatex standalone color

# LP-1
set linetype 1 linewidth 1 dashtype 1 linecolor "black"
# LP-M
set linetype 2 linewidth 1 dashtype 2 linecolor "black"
set linetype 3 linewidth 2 linecolor "white"

set xrange [0:1]
set yrange [0:1]
set zrange [0:1]

set pm3d depthorder hidden3d 3
set palette rgb 33,13,10
set hidden3d front
set grid
set dgrid3d 30,30 gauss .05

set xlabel "Utilization" rotate parallel
set ylabel "Growth Factor" rotate parallel
set zlabel "Schedulability Ratio" rotate parallel

# set output "output.eps"
# set title "(M=3, m=2, Sched) Schedulability Ratio"

#
# splot "M003m02-LP-1.data" using 1:2:3 title "LP-1" with lines lt 1, \
# 	"M003m02-LP-M.data" using 1:2:3 title "LP-M" with lines lt 2, \
#       "M003m03-TPJ-i.data" using 1:2:3 title "TPJ-i" with lines lt 3
#


