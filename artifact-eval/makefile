.PHONY: all 
BASE=main
TOP=$(BASE).pdf

BIBS=$(wildcard *.bib)
TEX=$(wilcdard *.tex)
PDFS=$(TOP)
VER=$(shell git rev-parse --short HEAD)
TMP=aux
PDFLATEX=pdflatex -halt-on-error -shell-escape -output-format=pdf -interaction=nonstopmode -output-directory=$(TMP)

all: $(TOP)

$(TOP): $(BASE).tex $(BIBS) | $(TMP) # Order only target
	$(PDFLATEX) -output-directory=$(TMP) ./$<
	$(PDFLATEX) -output-directory=$(TMP) ./$<
	cp $(TMP)/$(TOP) .

$(TMP):
	mkdir -p $@

clean:
	$(MAKE) -C clean
	-rm -rf *.bbl $(TOP) $(TMP)
