# Setup project dependencies
# ==========================

## Scholarly Metadata
SCHOLARLY_METADATA_VERSION = v1.0.1
SCHOLARLY_METADATA_URL = https://github.com/pandoc-scholar/scholarly-metadata/releases/download/

$(PANDOC_SCHOLAR_PATH)/scholarly-metadata scholarly-metadata:
	curl --location --remote-name \
		$(SCHOLARLY_METADATA_URL)/$(SCHOLARLY_METADATA_VERSION)/scholarly-metadata.tar.gz
	tar zvxf scholarly-metadata.tar.gz -C $(PANDOC_SCHOLAR_PATH)
	rm -f scholarly-metadata.tar.gz

clean-setup:
	rm -rf scholarly-metadata scholarly-metadata.tar.gz

.PHONY: clean
