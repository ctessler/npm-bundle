# -*- mode: gnuplot; -*-
#
# Template for generating 3D plots for one (M,m) of all algorithms.
#
# set terminal postscript eps color font "Times, 20"
# set terminal postscript eps enhanced color
set terminal epslatex standalone color
set termoption dashed

# LP-1
set linetype 1 linewidth 1 dashtype 1 linecolor "black"
# LP-M
set linetype 2 linewidth 1 dashtype 2 linecolor "black"

set linetype 3 linewidth 2 
set linetype 4 linewidth 2


set xrange [0:1]
set yrange [0:1]
set zrange [0:1]

#set pm3d depthorder hidden3d 1
set palette rgb 33,13,10
set hidden3d front
set grid
set dgrid3d 30,30 gauss .05

set xlabel "Utilization"
set ylabel "Growth Factor"
set zlabel "Schedulability Ratio"

# set output "output.eps"
# set title "(M=3, m=2) Schedulability Ratio"

#
# splot "M003m02-LP-1.data" using 1:2:3 title "LP-1" with lines, \
# 	"M003m02-LP-M.data" using 1:2:3 title "LP-M" with lines, \
#       "M003m03-TPJ-i.data" using 1:2:3 title "TPJ-i" with lines ...
#


