

all: Dokumentation.html Paper.pdf

Dokumentation.md: DotGentoo.md UseCases.md BLAS_Lapack.md BuildServer.md BuildServerExamples.md
	( for file in $^; do cat $$file; echo; done) > $@

%.html:%.md $(wildcard %.html.pre %.html.post)
	echo > $@
	if [[ -f $@.pre ]];then cat $@.pre > $@; fi
	cmark -t html $< | sed 's/\.png/\.svg/g' >> $@
	if [[ -f $@.post ]]; then cat $@.post >> $@; fi

Paper.pdf: Paper.tex $(patsubst %.md,%.tex,DotGentoo.md BLAS_Lapack.md BuildServer.md UseCases.md BuildServerExamples.md)
%.pdf: %.tex
	latexmk -lualatex $<

%.tex:%.md $(wildcard %.tex.pre %.tex.post)
	echo > $@
	if [[ -f $@.pre ]]; then cat $@.pre > $@; fi
	cmark --figures -t latex $< | sed 's/\.png/\.pdf/g; s/{verbatim}/{lstlisting}/g' | lua textttparse.lua >> $@
	if [[ -f $@.post ]]; then cat $@.post >> $@; fi

%.ms:%.md
	cmark -t man $^ > $@
