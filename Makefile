## The path to the directory in which this file resides. This allows users to
## include this Makefile into theirs and to reuse all rules, given that they set
## this variable to the correct value.
PANDOC_SCHOLAR_PATH   ?= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# include local makefile to allow easy overwriting of variables
-include local.mk
include $(PANDOC_SCHOLAR_PATH)/pandoc-options.inc.mk

# Local path in which Lua filters are stored. MUST include the trailing slash.
LUA_FILTERS_PATH      ?= $(PANDOC_SCHOLAR_PATH)/lua-filters/
# Lua filter release to use
LUA_FILTERS_VERSION   ?= v2020-11-29

# Configuration (overwrite using Makefile.local.in if necessary)
ARTICLE_FILE          ?= example/article.md
OUTFILE_PREFIX        ?= outfile
DEFAULT_EXTENSIONS    ?= latex pdf docx odt epub html
ADDITIONAL_EXTENSIONS ?= xml jats jsonld txt
JSON_FILE             ?= $(OUTFILE_PREFIX).enriched.json
FLATTENED_JSON_FILE   ?= $(OUTFILE_PREFIX).flattened.json

LUA_FILTER_NAMES      ?= cito.lua abstract-to-meta.lua scholarly-metadata.lua
LUA_FILTERS           ?= $(foreach f,$(LUA_FILTER_NAMES),$(LUA_FILTERS_PATH)$f)

default: $(addprefix $(OUTFILE_PREFIX).,$(DEFAULT_EXTENSIONS))
.PHONY: default

all: $(addprefix $(OUTFILE_PREFIX).,$(DEFAULT_EXTENSIONS)) \
     $(addprefix $(OUTFILE_PREFIX).,$(ADDITIONAL_EXTENSIONS))
.PHONY: all

$(JSON_FILE): $(ARTICLE_FILE) $(LUA_FILTERS)
	$(PANDOC) $(PANDOC_READER_OPTIONS) \
		     $(foreach filter, $(LUA_FILTERS), --lua-filter=$(filter)) \
	       --to=json \
	       --output=$@ $<

$(OUTFILE_PREFIX).pdf $(OUTFILE_PREFIX).latex: \
		$(JSON_FILE) \
		$(TEMPLATE_FILE_LATEX) \
		$(PANDOC_SCHOLAR_PATH)/scholar-filters/template-helper.lua
	$(PANDOC) $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_LATEX_OPTIONS) \
	       --lua-filter=$(PANDOC_SCHOLAR_PATH)/scholar-filters/template-helper.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).docx: $(JSON_FILE) \
		$(DOCX_REFERENCE_FILE) \
		$(LUA_FILTERS_PATH)author-info-blocks.lua
	$(PANDOC) $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_DOCX_OPTIONS) \
	       --lua-filter=$(LUA_FILTERS_PATH)/author-info-blocks.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).odt: $(JSON_FILE) \
		$(ODT_REFERENCE_FILE) \
		$(LUA_FILTERS_PATH)author-info-blocks.lua
	$(PANDOC) $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_ODT_OPTIONS) \
	       --lua-filter=$(LUA_FILTERS_PATH)author-info-blocks.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).epub: $(JSON_FILE) \
		$(TEMPLATE_FILE_EPUB) \
		$(LUA_FILTERS_PATH)author-info-blocks.lua
	$(PANDOC) $(PANDOC_WRITER_OPTIONS) \
	       $(PANDOC_EPUB_OPTIONS) \
	       --lua-filter=$(LUA_FILTERS_PATH)author-info-blocks.lua \
	       --output $@ $<

$(OUTFILE_PREFIX).html: $(JSON_FILE) \
		$(TEMPLATE_FILE_HTML) \
		$(TEMPLATE_STYLE_HTML) \
		$(PANDOC_SCHOLAR_PATH)/scholar-filters/template-helper.lua
	$(PANDOC) $(PANDOC_WRITER_OPTIONS) \
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
	$(PANDOC) --to $(PANDOC_SCHOLAR_PATH)/writers/jsonld.lua \
	       --lua-filter=$(PANDOC_SCHOLAR_PATH)/scholar-filters/json-ld.lua \
	       --output=$@ $<

$(OUTFILE_PREFIX).txt: $(ARTICLE_FILE)
	$(PANDOC) $(PANDOC_WRITER_OPTIONS) \
	       --output $@ $<

## Process the original ARTICLE_FILE instead of the pre-processed
## JSON file, as we need full control over bibliography handling
## to get acceptable JATS output. All PANDOC_WRITER_OPTIONS are
## omitted for the same reason.
##
## The JSON file is required only for metadata (csl) extraction
## by the jats-fixes.lua script, as pandoc overrides the CSL
## field when converting to JATS.
$(OUTFILE_PREFIX).jats $(OUTFILE_PREFIX).xml: \
		$(ARTICLE_FILE) \
		$(JSON_FILE) \
		$(PANDOC_SCHOLAR_PATH)/templates/pandoc-scholar.jats \
		$(PANDOC_SCHOLAR_PATH)/scholar-filters/jats-fixes.lua \
		$(PANDOC_SCHOLAR_PATH)/scholar-filters/template-helper.lua \
		$(PANDOC_SCHOLAR_PATH)/csl/chicago-author-date.csl \
		$(PANDOC_SCHOLAR_PATH)/csl/jats.csl
	$(PANDOC) \
	       $(PANDOC_READER_OPTIONS) \
	       $(PANDOC_JATS_OPTIONS) \
		     $(foreach filter, $(LUA_FILTERS), --lua-filter=$(filter)) \
	       --lua-filter=$(PANDOC_SCHOLAR_PATH)/scholar-filters/template-helper.lua \
	       --lua-filter=$(PANDOC_SCHOLAR_PATH)/scholar-filters/jats-fixes.lua \
	       --metadata=jats-csl=$(PANDOC_SCHOLAR_PATH)/csl/jats.csl \
	       --metadata=pandoc-scholar-json=$(JSON_FILE) \
	       --metadata=csl-path=$(PANDOC_SCHOLAR_PATH)/csl \
	       --to=jats \
	       --output $@ $<

ifneq ($(LUA_FILTERS_PATH),)
# Base release URL from which Lua filters are downloaded
lua_filters_url       ?= https://github.com/pandoc/lua-filters/releases

.PHONY: init
init: $(LUA_FILTERS_PATH)

$(LUA_FILTERS_PATH):
	mkdir -p $@
	curl --location --silent --show-error \
	    $(lua_filters_url)/download/$(LUA_FILTERS_VERSION)/lua-filters.tar.gz |\
      tar --strip-components=2 \
	        --one-top-level=$@ \
	        -zvxf - \
	        lua-filters/filters/

endif

clean:
	@# Explicitly iterate over known extensions instead of using a wildcard.
	@# This lets us avoid to accidentally delete any other files, e.g. if the
	@# ARTICLE_FILE happens to begin with OUTFILE_PREFIX.
	for ext in $(DEFAULT_EXTENSIONS) $(ADDITIONAL_EXTENSIONS); do\
		rm -f $(OUTFILE_PREFIX).$$ext;\
	done
	rm -f $(JSON_FILE) $(FLATTENED_JSON_FILE)

.PHONY: all

# Include archive-generating targets. This makefile is not included in the
# distributed archives
-include archives.inc.mk
