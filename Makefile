ARTICLE_FILE = example/article.md
BIBLIOGRAPHY_FILE = example/bibliography.bib
OUTFILE_PREFIX = outfile

ENRICHED_JSON_FILE = $(OUTFILE_PREFIX).enriched.json
FLATTENED_JSON_FILE = $(OUTFILE_PREFIX).flattened.json

## Pandoc options
PANDOC_READER_OPTIONS = --smart

PANDOC_WRITER_OPTIONS = --standalone
PANDOC_WRITER_OPTIONS += --metadata "bibliography:$(BIBLIOGRAPHY_FILE)"
PANDOC_WRITER_OPTIONS += --bibliography=$(BIBLIOGRAPHY_FILE)

PANDOC_LATEX_OPTIONS = --latex-engine=xelatex

PANDOC_NONTEX_OPTIONS = --filter pandoc-citeproc

## PanMeta
PANMETA_VERSION = v0.1.4
PANMETA_URL = https://github.com/formatting-science/panmeta/releases/download/$(PANMETA_VERSION)/panmeta.tar.gz

# Panlunatic uses this variable when deciding which JSON version should be
# emitted.
PANDOC_VERSION := $(shell pandoc -v | sed -ne 's/^pandoc //gp')
export PANDOC_VERSION

all: outfile.tex outfile.pdf outfile.epub outfile.html

$(ENRICHED_JSON_FILE): $(ARTICLE_FILE) panmeta
	pandoc $(PANDOC_READER_OPTIONS) \
	       -t panmeta/writers/affiliations.lua \
	       -o $@ $<

$(FLATTENED_JSON_FILE): $(ARTICLE_FILE) panmeta
	pandoc $(PANDOC_READER_OPTIONS) \
	       -t panmeta/writers/default.lua \
	       -o $@ $<

outfile.pdf outfile.tex: $(ENRICHED_JSON_FILE) $(ARTICLE_FILE) templates/panscimeta.latex
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_LATEX_OPTIONS) \
	       --template=templates/panscimeta.latex \
	       -o $@ $<

outfile.epub: $(FLATTENED_JSON_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_NONTEX_OPTIONS) \
	       --toc \
	       -o $@ $<

outfile.html: $(FLATTENED_JSON_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_NONTEX_OPTIONS) \
	       --toc \
				 --mathjax \
	       -o $@ $<

outfile.jsonld: $(ARTICLE_FILE) $(BIBLIOGRAPHY_FILE)
	pandoc -t panmeta/writers/jsonld.lua \
	       --metadata "bibliography:$(BIBLIOGRAPHY_FILE)" \
	       --output $@ $<

outfile.txt: $(ARTICLE_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       --output $@ $<

clean:
	rm -f $(OUTFILE_PREFIX).*

panmeta:
	curl --location --remote-name \
		https://github.com/formatting-science/panmeta/releases/download/$(PANMETA_VERSION)/panmeta.tar.gz
	tar zvxf panmeta.tar.gz

.PHONY: all clean release
