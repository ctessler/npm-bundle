EPS = $(wildcard ../plot/UFS-alg/*.eps)
TEX = $(patsubst %.eps,%.tex,$(EPS))
BTEX = $(patsubst ../plot/UFS-alg/%,%,$(TEX))

EPS2D = $(wildcard ../plot/2D-UFS/*.eps)
TEX2D = $(patsubst %.eps,%.tex,$(EPS2D))
BTEX2D = $(patsubst ../plot/2D-UFS/%,%,$(TEX2D))

%.tex: ../plot/UFS-alg/%.eps 
	./ufs-fig.sh $(shell echo $(subst .tex,,$@)) > $@

all: # all-figs.tex

all-figs.tex: ufstex 2dtex

ufstex: $(BTEX)
	rm -f all-figs.tex
	./allfigs.sh $(BTEX) >> all-figs.tex

%.tex: ../plot/2D-UFS/%.eps 
	./2dufs-fig.sh $(shell echo $(subst .tex,,$@)) > $@

2dtex: $(BTEX2D) ufstex
	./allfigs.sh $(BTEX2D) >> all-figs.tex


clean:
	rm -f $(BTEX) $(BTEX2D) all-figs.tex
