Pandoc Scholar
==============

[![release shield]](https://github.com/pandoc-scholar/pandoc-scholar/releases)
[![DOI]](https://zenodo.org/badge/latestdoi/82204858)
[![license shield]](./LICENSE)
[![build status]](https://travis-ci.org/pandoc-scholar/pandoc-scholar)

Create beautiful and semantically meaningful articles with pandoc. This package
provides utilities to make publishing of scientific articles as simple and
pleasant as possible.

[release shield]: https://img.shields.io/github/release/pandoc-scholar/pandoc-scholar.svg
[license shield]: https://img.shields.io/github/license/pandoc-scholar/pandoc-scholar.svg
[build status]:   https://img.shields.io/travis/pandoc-scholar/pandoc-scholar/master.svg
[DOI]: https://zenodo.org/badge/82204858.svg

Prerequisites
-------------

This package builds on [pandoc](http://pandoc.org/), the universal document
converter. See the pandoc website
for [installation instructions](http://pandoc.org/installing.html) and
suggestions for LaTeX packages, which we use for PDF generation.


Installation
------------

Archives containing all required files are provided for each release. Use the
*release* button above and download a `pandoc-scholar` archive; both archive
files, `.zip` and `.tar.gz`, contain the same files, choose the one most
convenient to you.

A `pandoc-scholar` folder will be created on unpacking. The folder contains all
required scripts and templates.


Usage
-----

Run `make` to convert the example article into all supported output formats. The
markdown file used to create the output files can be configured via the
`ARTICLE_FILE` variable, either directly in the Makefile or by specifying the
value on the command line.

    make ARTICLE_FILE=your-file.md


License
-------

Copyright © 2016–2017  Albert Krewinkel and Robert Winkler

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.
