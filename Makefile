## The path to the directory in which this file resides. This allows users to
## include this Makefile into theirs and to reuse all rules, given that they set
## this variable to the correct value.
PANDOC_SCHOLAR_PATH   ?= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

LUA_PATH              ?= $(PANDOC_SCHOLAR_PATH)/scholarly-metadata/?.lua;;
export LUA_PATH

# include local makefile to allow easy overwriting of variables
-include local.mk
include $(PANDOC_SCHOLAR_PATH)/pandoc-options.inc.mk

# Configuration (overwrite using Makefile.local.in if necessary)
ARTICLE_FILE          ?= example/article.md
OUTFILE_PREFIX        ?= outfile
DEFAULT_EXTENSIONS    ?= latex pdf docx odt epub html jats
ENRICHED_JSON_FILE    ?= $(OUTFILE_PREFIX).enriched.json
FLATTENED_JSON_FILE   ?= $(OUTFILE_PREFIX).flattened.json


all: $(addprefix $(OUTFILE_PREFIX).,$(DEFAULT_EXTENSIONS))

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

$(OUTFILE_PREFIX).pdf $(OUTFILE_PREFIX).latex: \
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

$(OUTFILE_PREFIX).html: $(ENRICHED_JSON_FILE) \
		$(TEMPLATE_FILE_HTML) \
		$(TEMPLATE_STYLE_HTML)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_HTML_OPTIONS) \
	       --css=$(TEMPLATE_STYLE_HTML) \
	       --self-contained \
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

clean:
	rm -f $(OUTFILE_PREFIX).*

.PHONY: all clean

# Include project-setup helpers
include $(PANDOC_SCHOLAR_PATH)/scholarly-metadata.inc.mk
# Include archive-generating targets. This makefile is not included in the
# distributed archives
-include archives.inc.mk
