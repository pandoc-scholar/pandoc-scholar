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

## Scholarly Metadata
SCHOLARLY_METADATA_VERSION = v0.1.5

# Panlunatic uses this variable when deciding which JSON version should be
# emitted.
PANDOC_VERSION := $(shell pandoc -v | sed -ne 's/^pandoc //gp')
export PANDOC_VERSION

all: $(OUTFILE_PREFIX).tex $(OUTFILE_PREFIX).pdf $(OUTFILE_PREFIX).epub $(OUTFILE_PREFIX).html

$(ENRICHED_JSON_FILE): $(ARTICLE_FILE) scholarly-metadata
	pandoc $(PANDOC_READER_OPTIONS) \
	       -t scholarly-metadata/writers/affiliations.lua \
	       -o $@ $<

$(FLATTENED_JSON_FILE): $(ARTICLE_FILE) scholarly-metadata
	pandoc $(PANDOC_READER_OPTIONS) \
	       -t scholarly-metadata/writers/default.lua \
	       -o $@ $<

$(OUTFILE_PREFIX).pdf $(OUTFILE_PREFIX).tex: $(ENRICHED_JSON_FILE) $(ARTICLE_FILE) templates/pandoc-scholar.latex
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_LATEX_OPTIONS) \
	       --template=./templates/pandoc-scholar.latex \
	       -o $@ $<

$(OUTFILE_PREFIX).epub: $(FLATTENED_JSON_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_NONTEX_OPTIONS) \
	       --toc \
	       -o $@ $<

$(OUTFILE_PREFIX).html: $(FLATTENED_JSON_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_NONTEX_OPTIONS) \
	       --toc \
				 --mathjax \
	       -o $@ $<

$(OUTFILE_PREFIX).jsonld: $(ARTICLE_FILE) $(BIBLIOGRAPHY_FILE)
	pandoc -t scholarly-metadata/writers/jsonld.lua \
	       --metadata "bibliography:$(BIBLIOGRAPHY_FILE)" \
	       --output $@ $<

$(OUTFILE_PREFIX).txt: $(ARTICLE_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       --output $@ $<

clean:
	rm -f $(OUTFILE_PREFIX).*

scholarly-metadata:
	curl --location --remote-name \
		https://github.com/pandoc-scholar/scholarly-metadata/releases/download/$(SCHOLARLY_METADATA_VERSION)/scholarly-metadata.tar.gz
	tar zvxf scholarly-metadata.tar.gz

.PHONY: all clean release
