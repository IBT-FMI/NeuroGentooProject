DOTFILES=$(wildcard *.dot)
DOTOPTS=-Gbgcolor="\#ffffff00"

all: $(patsubst %.dot, %.png, $(DOTFILES)) $(patsubst %.dot, %.svg, $(DOTFILES))$(patsubst %.dot, %.pdf, $(DOTFILES))

%.png: %.dot
	dot $(DOTOPTS) -Tpng $^ > $@
%.pdf: %.dot
	dot $(DOTOPTS) -Tpdf $^ > $@
%.svg: %.dot
	dot $(DOTOPTS) -Tsvg $^ > $@
