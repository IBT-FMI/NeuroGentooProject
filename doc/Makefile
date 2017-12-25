

all: Dokumentation.html

Dokumentation.md: DotGentoo.md BuildServer.md BLAS_Lapack.md
	( for file in $^; do cat $$file; echo; done) > $@

%.html:%.md $(wildcard %.html.pre %.html.post)
	echo > $@
	if [[ -f $@.pre ]];then cat $@.pre > $@; fi
	cmark -t html $< | sed 's/\.png/\.svg/g' >> $@
	if [[ -f $@.post ]]; then cat $@.post >> $@; fi

%.tex:%.md $(wildcard %.html.pre %.html.post)
	echo > $@
	if [[ -f $@.pre ]]; then cat $@.pre > $@; fi
	cmark -t tex $< | sed 's/\.png/\.svg/g' >> $@
	if [[ -f $@.post ]]; then cat $@.post >> $@; fi

%.ms:%.md
	cmark -t man $^ > $@
