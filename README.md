# pandoc-scholar

Create beautiful and semantically meaningful articles with pandoc. This package
provides everything to make publishing of scientific articles as simple and
pleasant as possible.

## Prerequisites

This package builds on [pandoc](http://pandoc.org/), the universal document
converter. See the pandoc website
for [installation instructions](http://pandoc.org/installing.html) and
suggestions for LaTeX packages, which we use for PDF generation.


## Installation

### git

    git clone https://github.com/pandoc-scholar/pandoc-scholar


## Usage

Run `make` to create all supported output formats from the example article. The
markdown file used to create the output files can be configured via the
`ARTICLE_FILE` variable, either directly in the Makefile or by specifying the
value on the command line.

    make ARTICLE_FILE=your-file.md

