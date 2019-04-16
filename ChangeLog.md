ChangeLog
=========

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
