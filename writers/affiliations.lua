--
-- affiliations.lua
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
setmetatable(_G, {__index = panlunatic})

local abstract = {}
local in_abstract = false

function Doc(body, meta, variables)
  meta.author, meta.institute =
    scholarlymeta.canonicalize_authors(meta.author, meta.institute)
  for i = 1, #meta.author do
    if meta.author[i].contributed_equally then
      meta.has_equal_contributors = panlunatic.Str "yes"
    end
    if meta.author[i].correspondence and meta.author[i].email then
      meta.has_correspondence = panlunatic.Str "yes"
    end
  end
  if next(abstract) ~= nil then
    meta.abstract = abstract
  else
    meta.abstract = panlunatic.Str("Not available")
  end
  return panlunatic.Doc(body, meta, variables)
end

function Cite (c, cs)
  for i = 1, #cs do
    _, cs[i].citationId = cito.cito_components(cs[i].citationId)
  end
  return panlunatic.Cite(c, cs)
end

function Header(lev, s, attr)
  in_abstract = (attr.id == "abstract")
  if in_abstract then
    return panlunatic.Plain(panlunatic.Str(' '))
  end
  return panlunatic.Header(lev, s, attr)
end

function Para(s)
  if in_abstract then
    table.insert(abstract, s)
    return panlunatic.Para(panlunatic.Str(' '))
  end
  return panlunatic.Para(s)
end
