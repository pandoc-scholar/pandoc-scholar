--
-- default.lua
--
-- Copyright (c) 2017 Albert Krewinkel, Robert Winkler
--
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU public license version 2 or later.
-- See the LICENSE file for details.

package.path = package.path .. ";scholarly-metadata/?.lua"

panlunatic = require "panlunatic"
scholarlymeta = require "scholarlymeta"
cito = require "cito"
titleblocks = require "titleblocks"
setmetatable(_G, {__index = panlunatic})

local abstract = {}
local in_abstract = false

function Doc(body, meta, variables)
  local authors, affiliations =
    scholarlymeta.canonicalize_authors(meta.author, meta.institute)

  meta.author = titleblocks.create_authors_inlines(authors)

  local corr = titleblocks.create_correspondence_block(authors)
  if corr then
    body = corr .. panlunatic.Blocksep() .. body
  end

  local contributors = titleblocks.create_equal_contributors_block(authors)
  if contributors then
    body = contributors .. panlunatic.Blocksep() .. body
  end

  body = titleblocks.create_affiliations_block(affiliations) ..
    panlunatic.Blocksep() .. body
  return panlunatic.Doc(body, meta, variables)
end

function Cite (c, cs)
  for i = 1, #cs do
    _, cs[i].citationId = cito.cito_components(cs[i].citationId)
  end
  return panlunatic.Cite(c, cs)
end
