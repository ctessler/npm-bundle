.PHONY: all svg plot tex
BASE=$(shell basename ${PWD})

TOP=$(BASE).pdf

BIBS=$(wildcard *.bib)
TEX=$(wilcdard *.tex)
PDFS=$(TOP)
VER=$(shell git rev-parse --short HEAD)

all: $(TOP)

$(TOP): tex
	mv tex/main.pdf $(TOP)
	cp $(TOP) $(TOP:.pdf=-$(VER).pdf)
	-echo -e "Current Revision:\n$(VER)"

tex: svg 
	$(MAKE) -C tex $(opt)

svg:
	$(MAKE) -C svg $(opt)

clean: opt=clean
clean: svg plot tex
clean:
	-rm -f $(BASE)*.pdf
