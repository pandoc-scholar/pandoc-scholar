ChangeLog
=========

v2.3.0
------

Released 2020-12-01

- Turned `example` dir into standalone example. The example is now
  clearer about how pandoc-scholar can be used when it was installed
  in a central location.

- Provide Docker images. Each new release is now accompanied by
  Docker images bundling all basic requirements into a single
  container. See the README for more info.

- Updated the LaTeX template. The template incorporates improvements
  from the latest pandoc version and will now also work with pandoc
  2.11.
  
- Renamed class given to the `<div>` wrapper around author
  affiliations. The class was named `author_affiliations`, but the
  CSS styles assumed `author-affiliations`. The HTML markup has been
  updated to match the CSS.

- Removed unneeded files from lua-filters. Files for testing have
  been dropped; only the filter files and docs are kept. The next
  major version will also change the directory structure below
  `lua-filters` and get rid of the separate subdirectories for each
  filter.

v2.2.2
------

Released 2020-06-17

- Update Lua filters to their most recent versions. This includes
  a fix to the abstract-to-meta filter, which would sometimes
  produce wrong results when used with pandoc 2.8 or newer.

v2.2.1
------

Released 2020-04-25

- Fixed incorrect path in JATS target: a file in the dependency
  list of the JATS target was missing was missing a path prefix,
  causing make to fail the Makefile was included in a different
  directory.

- Fixed bibliography and citation handling in JATS: citations
  were formatted incorrectly if no CSL file was given. We also
  make sure that `PANDOC_READER_OPTIONS` are respected for JATS.

- Simplify bibliography handling for JSON-LD: it is now
  sufficient to define a bibliography field in the article
  metadata. Previously, JSON-LD generation failed unless the
  `BIBLIOGRAPHY_FILE` variable was set; the requirement for this
  variable has been removed.

v2.2.0
------

Released 2020-04-21

- Running `make clean` is now ensured to only remove generated
  files (Sam Hiatt).

- JATS support has been improved and produces valid JATS 1.2
  documents using the Journal Archiving and Interchange tag set.
  Bibliography entries in the documents are formatted with the
  given CSL style.

- The default LaTeX template has been updated to work with pandoc
  2.9.

  + The options for the natbib package can be passed via the
    `natbiboptions` variable.

  + A new environment `cslreferences` is defined. It is used to
    contain pandoc-citeproc generated bibliographies.

- New make target `default` has been introduced. It is run
  instead of target `all` when make is called a specific target.

- The example is now generated with links between examples and
  references. Furthermore, the CSL file is explicitly defined to
  make it clearer how an alternative style can be used.

- The pandoc and pandoc-citeproc executables can now be set via
  the `PANDOC` and `PANDOC_CITEPROC` variables, respectively.
  The default is to use the binaries in the user's PATH.

v2.1.1
------

Released 2019-04-16

### Lua filters

- Fix a bug which caused separators to be inserted even for
  single authors. (#33)

v2.1.0
------

Released 2019-01-16.

### Templates

- Removed a newline in the HTML template which caused an extra
  space be inserted before institute addresses (Benjamin Lee).

- Include subtitle in PDF output (solution taken from pandoc,
  courtesy of Andrew Dunning).

v2.0.1
------

Released 2018-12-26.

### Makefile

- Fix option for docx reference documents. (Mitchell Paulus)

- Fix option for odt reference documents.

### Lua filters

- Fix filters for pandoc 2.3 and later; older versions should
  continue to work.

- author-info-blocks:

  + Fix LaTeX output, surround `\dagger` with dollars.

  + Keep authors as a list instead of joining them into a single
    entry when the output is LaTeX. This fixes LaTeX layout
    issues when many authors are given.

- pagebreak: New filter to convert `\newpage` commands into
  target-format appropriate page breaks. Not enabled by default.

- multiple-bibliographies: a filter which allows the creation of
  multiple bibliographies using `pandoc-citeproc`.
  Not enabled by default.


v2.0.0
------

- Update to pandoc 2. Pandoc scholar now requires pandoc 2.1 or later.

- The internal document transformation system has been mostly
  rewritten. Instead of custom writers based on panlunatic, the
  new version now uses pandoc Lua filters. This builds on a
  well-tested system and removes some bugs due caused by
  panlunatic. Lua filters are also easier to use separately.
  E.g., using Lua filters allows to integrate desired
  functionality into a RMarkdown workflow.

- Added support for CiTO property
  *cites\_as\_recommended\_reading*.

- Add missing author affiliations in HTML output (Thomas Sibley).

- JATS support no longer relies on a custom writer; output is
  generated directly via pandoc.

- Fixed sub/sup styling in HTML output
