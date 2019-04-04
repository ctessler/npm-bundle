			 EVALUATION DIRECTORY

This directory contains all of the source for creating the data sets
and analysis used in the paper. It relies upon the libsched package
available on github.

	libsched	-- github.com/ctessler/libsched.git

The libsched library and binaries must be built and installed.
Additionally, the binaries of libsched must be accessible in the PATH.

Directories:
	bin/	-- The scripts used to generate the data
	cfg/	-- Configuration files for generating task sets
	run/	-- A working directory, where the current run will
		   execute
	data/	-- The resulting data from the latest run (as a
		   shorthand cp -r run data after completion)
	plot/	-- The plot sources, which use the data/
	svg/	-- Graphs generated from the plot/ sources

Usage:
	make clean 	# Cleans the run directory
	make sanitary	# Removes **EVERYTHING**
	make run	# Runs the evaluation
	     		# With the default parameters, this will consume
			# 2.3 gigabytes of data
	make data	# Moves the latest run directory to data
	make plot	# Creates the plots from the data
	make		# Will *only* generate the plots


			FROM A FRESH CHECKOUT

> make run	# Go out for the weekend
> make data	
> make plot	# Full results in plot/all-plots.pdf
