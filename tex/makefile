.PHONY: all 80-appendix
BASE=main
TOP=$(BASE).pdf

BIBS=$(wildcard *.bib)
TEX=$(wilcdard *.tex)
PDFS=$(TOP)
VER=$(shell git rev-parse --short HEAD)
TMP=aux
PDFLATEX=pdflatex -halt-on-error -shell-escape -output-format=pdf -interaction=nonstopmode -output-directory=$(TMP)

define PLOTERROR
A plot directory is required.

Either A.) copy or B.) symlink one from the eval directory. From within
the directory containing this makefile, 
    A.) cp -r ../eval/plot  .
    B.) ln -s ../eval/plot plot	

endef

all: $(TOP)

$(TOP): export TEXINPUTS=../lipics-v2018-authors:
$(TOP): $(BASE).tex $(BIBS) 80-appendix | $(TMP) plot # Order only target
	$(PDFLATEX) -output-directory=$(TMP) ./$<
	TEXMFOUTPUT="$(TMP):" bibtex $(TMP)/$(BASE)
	$(PDFLATEX) -output-directory=$(TMP) ./$<
	$(PDFLATEX) -output-directory=$(TMP) ./$<
	cp $(TMP)/$(TOP) .

plot:
	$(error $(PLOTERROR))

80-appendix: | plot
	$(MAKE) -C $@ $(opt)

$(TMP):
	mkdir -p $@

clean:
	$(MAKE) -C 80-appendix clean
	-rm -rf *.bbl $(TOP) $(TMP)
