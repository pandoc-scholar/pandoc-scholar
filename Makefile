## The path to the directory in which this file resides. This allows users to
## include this Makefile into theirs and to reuse all rules, given that they set
## this variable to the correct value.
PANDOC_SCHOLAR_PATH   ?= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# include local makefile to allow easy overwriting of variables
-include local.mk
include $(PANDOC_SCHOLAR_PATH)/pandoc-options.inc.mk

LUA_FILTERS_PATH      ?= $(PANDOC_SCHOLAR_PATH)/lua-filters

# Configuration (overwrite using Makefile.local.in if necessary)
ARTICLE_FILE          ?= example/article.md
OUTFILE_PREFIX        ?= outfile
DEFAULT_EXTENSIONS    ?= latex pdf docx odt epub html
JSON_FILE             ?= $(OUTFILE_PREFIX).enriched.json
FLATTENED_JSON_FILE   ?= $(OUTFILE_PREFIX).flattened.json
LUA_FILTERS           ?= $(LUA_FILTERS_PATH)/cito/cito.lua \
                         $(LUA_FILTERS_PATH)/abstract-to-meta/abstract-to-meta.lua \
                         $(LUA_FILTERS_PATH)/scholarly-metadata/scholarly-metadata.lua


all: $(addprefix $(OUTFILE_PREFIX).,$(DEFAULT_EXTENSIONS))

$(JSON_FILE): $(ARTICLE_FILE) $(LUA_FILTERS)
	pandoc $(PANDOC_READER_OPTIONS) \
		     $(foreach filter, $(LUA_FILTERS), --lua-filter=$(filter)) \
	       --to=json \
	       --output=$@ $<

$(OUTFILE_PREFIX).pdf $(OUTFILE_PREFIX).latex: \
		$(JSON_FILE) \
		$(TEMPLATE_FILE_LATEX) \
		$(PANDOC_SCHOLAR_PATH)/scholar-filters/template-helper.lua
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_LATEX_OPTIONS) \
	       --lua-filter=$(PANDOC_SCHOLAR_PATH)/scholar-filters/template-helper.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).docx: $(JSON_FILE) \
		$(ODT_REFERENCE_FILE) \
		$(LUA_FILTERS_PATH)/author-info-blocks/author-info-blocks.lua
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_DOCX_OPTIONS) \
	       --lua-filter=$(LUA_FILTERS_PATH)/author-info-blocks/author-info-blocks.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).odt: $(JSON_FILE) \
		$(ODT_REFERENCE_FILE) \
		$(LUA_FILTERS_PATH)/author-info-blocks/author-info-blocks.lua
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_ODT_OPTIONS) \
	       --lua-filter=$(LUA_FILTERS_PATH)/author-info-blocks/author-info-blocks.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).epub: $(JSON_FILE) \
		$(TEMPLATE_FILE_EPUB) \
		$(LUA_FILTERS_PATH)/author-info-blocks/author-info-blocks.lua
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_EPUB_OPTIONS) \
	       --lua-filter=$(LUA_FILTERS_PATH)/author-info-blocks/author-info-blocks.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).html: $(JSON_FILE) \
		$(TEMPLATE_FILE_HTML) \
		$(TEMPLATE_STYLE_HTML) \
		$(PANDOC_SCHOLAR_PATH)/scholar-filters/template-helper.lua
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_HTML_OPTIONS) \
	       --lua-filter=$(PANDOC_SCHOLAR_PATH)/scholar-filters/template-helper.lua \
	       --css=$(TEMPLATE_STYLE_HTML) \
	       --self-contained \
	       --mathjax \
	       --output $@ $<

$(OUTFILE_PREFIX).jsonld: $(JSON_FILE) \
		$(BIBLIOGRAPHY_FILE) \
		$(PANDOC_SCHOLAR_PATH)/scholar-filters/json-ld.lua \
		$(PANDOC_SCHOLAR_PATH)/writers/jsonld.lua
	pandoc --to $(PANDOC_SCHOLAR_PATH)/writers/jsonld.lua \
	       --metadata "bibliography:$(BIBLIOGRAPHY_FILE)" \
	       --lua-filter=$(PANDOC_SCHOLAR_PATH)/scholar-filters/json-ld.lua \
	       --output=$@ $<

$(OUTFILE_PREFIX).txt: $(ARTICLE_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       --output $@ $<

## Advanced JATS support is temporarily disabled.
$(OUTFILE_PREFIX).jats: $(JSON_FILE)
	pandoc $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_JATS_OPTIONS) \
	       --output $@ $<

clean:
	rm -f $(OUTFILE_PREFIX).*

.PHONY: all clean

# Include archive-generating targets. This makefile is not included in the
# distributed archives
-include archives.inc.mk
