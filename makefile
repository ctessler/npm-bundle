.PHONY: all svg export
BASE=npm-bundle
TOP=$(BASE).pdf

BIBS=$(wildcard *.bib)
TEX=$(wilcdard *.tex)
PDFS=$(TOP)
VER=$(shell git rev-parse --short HEAD)
TMP=aux
PDFLATEX=pdflatex -halt-on-error -shell-escape -output-format=pdf \
    -interaction=nonstopmode -output-directory=$(TMP)

all: $(TOP)

$(TOP): export TEXINPUTS=lipics-v2019-authors:
$(TOP): $(BASE).tex $(BIBS) svg | $(TMP) plot # Order only target
	$(PDFLATEX) -output-directory=$(TMP) ./$<
	TEXMFOUTPUT="$(TMP):" bibtex $(TMP)/$(BASE)
	cp $(TMP)/$(TOP) .
	cp $(TOP) $(TOP:.pdf=-$(VER).pdf)
	-echo -e "Current Revision:\n$(VER)"

svg:
	$(MAKE) -C svg $(opt)

# A temporary director to hold the intermediate contents
$(TMP):
	mkdir -p $@

clean: opt=clean
clean: svg
clean:
	-rm -f $(BASE)*.pdf

export: svg $(TOP)
	tar cvzf npm-bundle.tar.gz --transform 's,^,npm-bundle/,' \
	    lipics-v2019-authors plot svg/*.pdf npm-bundle.tex \
	    npm-bundle.bib $(TOP)
