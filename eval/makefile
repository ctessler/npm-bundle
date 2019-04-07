# COUNT is the number of tasks per configuration
COUNT=1000
COUNT=10

runargs=-M "3, 5, 7, 10, 25, 50, 100" -m "2, 2, 3, 4, 8, 16, 32" 
runargs+=-f .1 -F .9 -u .1 -U .9 -S $(COUNT) -b ../../cfg/base.tp
case_study_args=-c $(COUNT) -u .1 -U 1.0

.PHONY: all 

all: plot

run: run/avg-ratio-done run/UFxS-done run/oo-done run/cs-ratio-data-done
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

#cs refers to Case Study
run/cs-ratio-data-done: run/cs-ratio-done
	mkdir -p run/cs-ratio-data
	cd run/cs-ratio-data; time cs-ratio-data.sh $(case_study_args) ../cs-ratio
	touch run/cs-ratio-done

run/cs-ratio-done: run/cs-sched-done
	mkdir -p run/cs-ratio
	cd run/cs-ratio; time cs-sched-ratios.sh $(case_study_args) ../cs-sched
	touch run/cs-ratio-done

run/cs-sched-done: run/cs-taskset-done
	mkdir -p run/cs-sched
	cd run/cs-sched; time cs-sched-test-sets.sh $(case_study_args) ../cs
	touch run/cs-sched-done

run/cs-taskset-done:
	mkdir -p run/cs
	cd run/cs; time cs-tasks.sh $(case_study_args) -s ../../cfg/bundlep.ts \
		-b ../../cfg/case-study.tp

	touch run/cs-taskset-done

run/taskset-done:
	mkdir -p run/ts  	# the task set directory
	cd run/ts; time incip-sets.sh $(runargs)
	touch run/taskset-done

data:
	mv -n run data
	rm data/*-done
data-clean:
	rm -rf data

plot: plot/all-plots.pdf plot/oo-done plot/cs-ratio/cs-ratio.pdf data
plot-clean:
	rm -rf plot

plot/cs-ratio/cs-ratio.pdf: data
	mkdir -p plot/cs-ratio
	cp cfg/CS-UxS.p plot/cs-ratio/.
	cd plot/cs-ratio ; time gnuplot CS-UxS.p
	cd plot/cs-ratio ; time pdflatex cs-ratio.tex > /dev/null

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
