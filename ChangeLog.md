ChangeLog
=========

v2.0.0
------

- Update to pandoc 2. Pandoc scholar now requires pandoc 2.1 or later.
- The internal document transformation system has been mostly rewritten. Instead
  of custom writers based on panlunatic, the new version now uses pandoc Lua
  filters. This builds on a well-tested system and removes some bugs due caused
  by panlunatic. Lua filters are also easier to use separately. E.g., using Lua
  filters allows to integrate desired functionality into a RMarkdown workflow.
- Added support for CiTO property *cites\_as\_recommended\_reading*.
- Add missing author affiliations in HTML output (Thomas Sibley).
- JATS support no longer relies on a custom writer; output is generated directly
  via pandoc.
- Fixed sub/sup styling in HTML output
