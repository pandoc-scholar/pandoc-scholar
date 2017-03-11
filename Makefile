ARTICLE_FILE          ?= example/article.md
OUTFILE_PREFIX        ?= outfile
DEFAULT_EXTENSIONS    ?= tex pdf docx odt epub html jats

ENRICHED_JSON_FILE    ?= $(OUTFILE_PREFIX).enriched.json
FLATTENED_JSON_FILE   ?= $(OUTFILE_PREFIX).flattened.json

TEMPLATE_FILE_LATEX   ?= $(PANDOC_SCHOLAR_PATH)/templates/pandoc-scholar.latex
TEMPLATE_FILE_JATS    ?= $(PANDOC_SCHOLAR_PATH)/jats/default.jats

## Pandoc options
PANDOC_READER_OPTIONS ?= --smart

ifndef PANDOC_WRITER_OPTIONS
PANDOC_WRITER_OPTIONS  = --standalone
PANDOC_WRITER_OPTIONS += --filter=pandoc-citeproc
ifdef BIBLIOGRAPHY_FILE
PANDOC_WRITER_OPTIONS += --metadata "bibliography:$(BIBLIOGRAPHY_FILE)"
PANDOC_WRITER_OPTIONS += --bibliography=$(BIBLIOGRAPHY_FILE)
endif
endif

PANDOC_ODT_OPTIONS    ?=
PANDOC_DOCX_OPTIONS   ?=
PANDOC_HTML_OPTIONS   ?=
PANDOC_EPUB_OPTIONS   ?=
ifndef PANDOC_LATEX_OPTIONS
PANDOC_LATEX_OPTIONS   = --latex-engine=xelatex
endif

ifdef ODT_REFERENCE_FILE
PANDOC_ODT_OPTIONS    += --reference-odt=$(ODT_REFERENCE_FILE)
endif
ifdef DOCX_REFERENCE_FILE
PANDOC_DOCX_OPTIONS   += --reference-docx=$(DOCX_REFERENCE_FILE)
endif
ifdef TEMPLATE_FILE_LATEX
PANDOC_LATEX_OPTIONS   += --template=$(TEMPLATE_FILE_LATEX)
endif
ifdef TEMPLATE_FILE_HTML
PANDOC_HTML_OPTIONS   += --template=$(TEMPLATE_FILE_HTML)
endif
ifdef TEMPLATE_FILE_EPUB
PANDOC_EPUB_OPTIONS   += --template=$(TEMPLATE_FILE_EPUB)
endif
ifdef TEMPLATE_FILE_JATS
PANDOC_JATS_OPTIONS   += --template=$(TEMPLATE_FILE_JATS)
endif

## The path to the directory in which this file resides. This allows users to
## include this Makefile into theirs and to reuse all rules, given that they set
## this variable to the correct value.
PANDOC_SCHOLAR_PATH   ?= .

## Scholarly Metadata
SCHOLARLY_METADATA_VERSION = v1.0.0
SCHOLARLY_METADATA_URL = https://github.com/pandoc-scholar/scholarly-metadata/releases/download/

# Panlunatic uses this variable when deciding which JSON version should be
# emitted.
PANDOC_VERSION := $(shell pandoc -v | sed -ne 's/^pandoc //gp')
export PANDOC_VERSION

all: $(foreach extension,$(DEFAULT_EXTENSIONS),$(OUTFILE_PREFIX).$(extension))

$(OUTFILE_PREFIX).enriched.json: $(ARTICLE_FILE) \
		$(PANDOC_SCHOLAR_PATH)/scholarly-metadata \
		$(PANDOC_SCHOLAR_PATH)/writers/affiliations.lua
	pandoc $(PANDOC_READER_OPTIONS) \
	       -t $(PANDOC_SCHOLAR_PATH)/writers/affiliations.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).flattened.json: $(ARTICLE_FILE) \
		$(PANDOC_SCHOLAR_PATH)/scholarly-metadata \
		$(PANDOC_SCHOLAR_PATH)/writers/default.lua
	pandoc $(PANDOC_READER_OPTIONS) \
	       -t $(PANDOC_SCHOLAR_PATH)/writers/default.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).pdf $(OUTFILE_PREFIX).tex: \
		$(ENRICHED_JSON_FILE) \
		$(TEMPLATE_FILE_LATEX)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_LATEX_OPTIONS) \
	       --output $@ $<

$(OUTFILE_PREFIX).docx: $(FLATTENED_JSON_FILE) \
		$(ODT_REFERENCE_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_DOCX_OPTIONS) \
	       --output $@ $<

$(OUTFILE_PREFIX).odt: $(FLATTENED_JSON_FILE) \
		$(ODT_REFERENCE_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_ODT_OPTIONS) \
	       --output $@ $<

$(OUTFILE_PREFIX).epub: $(FLATTENED_JSON_FILE) \
		$(TEMPLATE_FILE_EPUB)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_EPUB_OPTIONS) \
	       --output $@ $<

$(OUTFILE_PREFIX).html: $(FLATTENED_JSON_FILE) \
		$(TEMPLATE_FILE_HTML)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_HTML_OPTIONS) \
	       --mathjax \
	       --output $@ $<

$(OUTFILE_PREFIX).jsonld: $(ARTICLE_FILE) \
		$(BIBLIOGRAPHY_FILE) \
		$(PANDOC_SCHOLAR_PATH)/writers/jsonld.lua
	pandoc -t $(PANDOC_SCHOLAR_PATH)/writers/jsonld.lua \
	       --metadata "bibliography:$(BIBLIOGRAPHY_FILE)" \
	       --output $@ $<

$(OUTFILE_PREFIX).txt: $(ARTICLE_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       --output $@ $<

$(OUTFILE_PREFIX).jats: \
		$(ENRICHED_JSON_FILE) \
		$(PANDOC_SCHOLAR_PATH)/scholarly-metadata \
		$(TEMPLATE_FILE_JATS)
	pandoc -t $(PANDOC_SCHOLAR_PATH)/jats/JATS.lua \
	       $(PANDOC_JATS_OPTIONS) \
	       --output $@ $<

### GET DEPENDENCIES

scholarly-metadata:
	curl --location --remote-name \
		$(SCHOLARLY_METADATA_VERSION)/scholarly-metadata.tar.gz
	tar zvxf scholarly-metadata.tar.gz
	rm -f scholarly-metadata.tar.gz


### BUILD ARCHIVES

archives: dist/pandoc-scholar.zip dist/pandoc-scholar.tar.gz

dist/pandoc-scholar: \
                scholarly-metadata \
                LICENSE Makefile README.md \
                example jats templates writers
	mkdir -p dist/pandoc-scholar
	rm -rf dist/pandoc-scholar/*
	cp -av $^ dist/pandoc-scholar

dist/pandoc-scholar.tar.gz: dist/pandoc-scholar
	tar zvcf dist/pandoc-scholar.tar.gz -C dist pandoc-scholar

dist/pandoc-scholar.zip: dist/pandoc-scholar
	(cd dist && zip -r pandoc-scholar.zip pandoc-scholar)

clean:
	rm -f $(OUTFILE_PREFIX).*

dist-clean: clean
	rm -rf scholarly-metadata scholarly-metadata.tar.gz

.PHONY: all clean archives
