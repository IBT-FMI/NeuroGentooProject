DOTFILES=$(wildcard *.dot)
FONT="STIX"
FONTSIZE="11.0"
DOTOPTS=-Gbgcolor="\#ffffff00" $(addsuffix fontname=$(FONT),-G -N -E) $(addsuffix fontsize=$(FONTSIZE),-G -N -E)

all: $(patsubst %.dot, %.png, $(DOTFILES)) $(patsubst %.dot, %.svg, $(DOTFILES))$(patsubst %.dot, %.pdf, $(DOTFILES))

%.png: %.dot
	dot $(DOTOPTS) -Tpng $^ > $@
%.pdf: %.dot
	dot $(DOTOPTS) -Tpdf $^ > $@.tmp
	pdfcrop $@.tmp $@
	rm $@.tmp
%.svg: %.dot
	dot $(DOTOPTS) -Tsvg $^ > $@
