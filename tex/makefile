.PHONY: all
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

$(TOP): export TEXINPUTS=../lipics-v2019-authors:
$(TOP): $(BASE).tex $(BIBS) | $(TMP) plot # Order only target
	$(PDFLATEX) -output-directory=$(TMP) ./$<
	TEXMFOUTPUT="$(TMP):" bibtex $(TMP)/$(BASE)
	$(PDFLATEX) -output-directory=$(TMP) ./$<
	$(PDFLATEX) -output-directory=$(TMP) ./$<
	cp $(TMP)/$(TOP) .

plot:
	$(error $(PLOTERROR))

$(TMP):
	mkdir -p $@

clean:
	-rm -rf *.bbl $(TOP) $(TMP)
