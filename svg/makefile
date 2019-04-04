#
# Scaled Vector Graphics Makefile by Corey Tessler
#
SVGS = $(wildcard *.svg)
PDFS = $(patsubst %.svg,%.pdf_tex,$(SVGS))

all: $(PDFS)

%.pdf_tex: %.svg
	inkscape $^ -z -D --export-latex --export-pdf=$(^:.svg=.pdf)

clean:
	rm -rf *.pdf *.pdf_tex
