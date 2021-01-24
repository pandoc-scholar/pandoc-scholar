# Settings for Pandoc
# ===================

TEMPLATE_FILE_LATEX   ?= $(PANDOC_SCHOLAR_PATH)/templates/pandoc-scholar.latex
TEMPLATE_FILE_HTML    ?= $(PANDOC_SCHOLAR_PATH)/templates/pandoc-scholar.html
TEMPLATE_FILE_JATS    ?= $(PANDOC_SCHOLAR_PATH)/templates/pandoc-scholar.jats

TEMPLATE_STYLE_HTML   ?= $(PANDOC_SCHOLAR_PATH)/templates/styles/pandoc-scholar.css

## Pandoc options
PANDOC_READER_OPTIONS ?=
ifdef BIBLIOGRAPHY_FILE
PANDOC_READER_OPTIONS += --metadata "bibliography:$(BIBLIOGRAPHY_FILE)"
endif

ifndef PANDOC_WRITER_OPTIONS
PANDOC_WRITER_OPTIONS  = --standalone
PANDOC_WRITER_OPTIONS += --citeproc
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
PANDOC_LATEX_OPTIONS   = --pdf-engine=xelatex
endif

ifdef ODT_REFERENCE_FILE
PANDOC_ODT_OPTIONS    += --reference-doc=$(ODT_REFERENCE_FILE)
endif
ifdef DOCX_REFERENCE_FILE
PANDOC_DOCX_OPTIONS   += --reference-doc=$(DOCX_REFERENCE_FILE)
endif
ifdef TEMPLATE_FILE_LATEX
PANDOC_LATEX_OPTIONS  += --template=$(TEMPLATE_FILE_LATEX)
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
