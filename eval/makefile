runargs=-M "3, 5, 7, 10, 25, 50, 100" -m "2, 2, 3, 4, 8, 16, 32" 
runargs+=-f .1 -F .9 -u .1 -U .9 -S 1000 -b ../../cfg/base.tp

# runargs=-M "3, 5, 7, 10, 25, 50, 100" -m "2, 2, 3, 4, 8, 16, 32" 
# runargs+=-f .1 -F .9 -u .1 -U .9 -S 10 -b ../../cfg/base.tp

.PHONY: all 

all: plot

run: run/avg-ratio-done run/UFxS-done run/oo-done
run-clean:
	rm -rf run

run/oo-done: run/sched-done
	mkdir -p run/over-one
	cd run/over-one ; time over-one.sh $(runargs) ../sched ../ts
	touch run/oo-done

run/UFxS-done: run/rba-done
	mkdir -p run/UFxS
	cd run/UFxS ; time UFxS-by-alg.sh $(runargs) ../ratio-by-alg
	touch run/UFxS-done

run/avg-ratio-done: run/rba-done
	mkdir -p run/avg-ratio-by-alg
	cd run/avg-ratio-by-alg ; time avg-ratio-by-alg.sh $(runargs) ../ratio-by-alg
	touch run/avg-ratio-done

run/rba-done: run/sched-ratio-done
	mkdir -p run/ratio-by-alg
	cd run/ratio-by-alg ; time ratio-by-alg.sh $(runargs) ../ratio
	touch run/rba-done

run/sched-ratio-done: run/sched-done
	mkdir -p run/ratio
	cd run/ratio ; time sched-ratio-sets.sh $(runargs) ../sched
	touch run/sched-ratio-done

run/sched-done: run/taskset-done
	mkdir -p run/sched
	cd run/sched; time sched-test-sets.sh $(runargs) ../ts
	touch run/sched-done

run/taskset-done:
	mkdir -p run/ts  	# the task set directory
	cd run/ts; time incip-sets.sh $(runargs)
	touch run/taskset-done

data:
	mv -n run data
	rm data/taskset-done
	rm data/sched-done
	rm data/sched-ratio-done
	rm data/rba-done
data-clean:
	rm -rf data

plot: plot/all-plots.pdf plot/oo-done data
plot-clean:
	rm -rf plot

plot/oo-done:
	mkdir -p plot/over-one
	cd plot/over-one ; time table-over-one.sh $(runargs) ../../data/over-one
	touch plot/oo-done

plot/all-plots.pdf: plot/UFS-done plot/UFS-alg-done plot/aas-done plot/2D-UFS-done 
	cd plot/ ; time all-plots.sh
	cd plot/ ; time pdflatex all-plots.tex > /dev/null

plot/2D-UFS-done:
	mkdir -p plot/2D-UFS
	cd plot/2D-UFS ; time plot-UFxS.sh $(runargs) ../../data/UFxS
	touch plot/2D-UFS-done

plot/aas-done:
	mkdir -p plot/avg-alg-sched
	cd plot/avg-alg-sched ; time plot-avg-ratio-vs-edfp.sh \
		$(runargs) ../../data/avg-ratio-by-alg
	touch plot/aas-done

plot/UFS-alg-done:
	mkdir -p plot/UFS-alg
	cd plot/UFS-alg ; time plot-alg-vs-edfp.sh $(runargs) ../../data/ratio-by-alg
	touch plot/UFS-alg-done

plot/UFS-done:
	mkdir -p plot/UFS
	cd plot/UFS ; time plot-ratio-for-mm.sh $(runargs) ../../data/ratio-by-alg
	touch plot/UFS-done

# Cleans the run directory
clean: run-clean 
	make -C svg clean

# Deletes e'rything
sanitary: clean plot-clean data-clean
