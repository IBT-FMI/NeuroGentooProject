

all: Dokumentation.html

Dokumentation.md: DotGentoo.md BLAS_Lapack.md BuildServer.md UseCases.md
	( for file in $^; do cat $$file; echo; done) > $@

%.html:%.md $(wildcard %.html.pre %.html.post)
	echo > $@
	if [[ -f $@.pre ]];then cat $@.pre > $@; fi
	cmark -t html $< | sed 's/\.png/\.svg/g' >> $@
	if [[ -f $@.post ]]; then cat $@.post >> $@; fi

%.tex:%.md $(wildcard %.tex.pre %.tex.post)
	echo > $@
	if [[ -f $@.pre ]]; then cat $@.pre > $@; fi
	cmark -t latex $< | sed 's/\.png/\.pdf/g' >> $@
	if [[ -f $@.post ]]; then cat $@.post >> $@; fi

%.ms:%.md
	cmark -t man $^ > $@
