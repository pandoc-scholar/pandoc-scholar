ARTICLE_FILE = example/article.md
OUTFILE_PREFIX = outfile

ENRICHED_JSON_FILE = $(OUTFILE_PREFIX).enriched.json

PANMETA_VERSION = v0.1.1
PANMETA_URL = https://github.com/formatting-science/panmeta/releases/download/$(PANMETA_VERSION)/panmeta.tar.gz

# Panlunatic uses this variable when deciding which JSON version should be
# emitted.
PANDOC_VERSION := $(shell pandoc -v | sed -ne 's/^pandoc //gp')
export PANDOC_VERSION

all: $(ENRICHED_JSON_FILE)

$(ENRICHED_JSON_FILE): $(ARTICLE_FILE) panmeta
	pandoc $(PANDOC_READER_OPTIONS) \
	       -t panmeta/writers/affiliations.lua \
	       -o $@ $<

clean:
	rm -f $(OUTFILE_PREFIX).*

panmeta:
	curl --location --remote-name \
		https://github.com/formatting-science/panmeta/releases/download/$(PANMETA_VERSION)/panmeta.tar.gz
	tar zvxf panmeta.tar.gz

.PHONY: all clean release
