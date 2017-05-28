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
setmetatable(_G, {__index = panlunatic})

local abstract = {}
local in_abstract = false

function Doc(body, meta, variables)
  local authors, affiliations =
    scholarlymeta.canonicalize_authors(meta.author, meta.institute)
  meta.author = {}

  local author_notes = {}
  for i = 0, #authors do
    author_notes[i] = {}
  end

  -- Corresponding authors
  local corresponding_authors = {}
  for k, author in ipairs(authors) do
    if author.correspondence and author.email then
      local mailto = "mailto:" .. panlunatic.decode(author.email).c
      local envelope = panlunatic.Superscript(panlunatic.Str "✉")
      local attr = {id = "", class = ""}
      local link = panlunatic.Link(envelope, mailto, "", attr)
      local author_with_mail =
        author.name .. panlunatic.Space() .. panlunatic.Str "<" ..
        author.email .. panlunatic.Str ">"
      table.insert(author_notes[k], panlunatic.Link(envelope, mailto, "", attr))
      table.insert(
        corresponding_authors,
        panlunatic.Link(author_with_mail, mailto, "", attr)
      )
    end
  end
  if #corresponding_authors > 0 then
    local correspondence = panlunatic.Str "Correspondence:" .. panlunatic.Space()
    local sep = panlunatic.Str "," .. panlunatic.Space()
    body = panlunatic.Para(correspondence .. table.concat(corresponding_authors, sep)) ..
      ',' .. body
  end

  -- Equal contributions
  local has_equal_contributors = false
  for k, author in ipairs(authors) do
    if author.equal_contributor then
      has_equal_contributors = true
      table.insert(author_notes[k], panlunatic.Str "*")
    end
  end
  if has_equal_contributors then
    local contributors =
      panlunatic.Superscript(panlunatic.Str "*") ..
      panlunatic.Space() ..
      panlunatic.Str "These authors contributed equally to this work."
    body = panlunatic.Para(contributors) .. panlunatic.Blocksep() .. body
  end

  for k, author in ipairs(authors) do
    for _, idx in ipairs(author.institute_indices) do
      table.insert(author_notes[k], panlunatic.Str(tostring(idx)))
    end
  end
  for k, author in ipairs(authors) do
    meta.author[k] = author.name ..
      panlunatic.Superscript(table.concat(author_notes[k], panlunatic.Str ","))
  end

  -- meta.institute = affiliations:map(function(inst) return inst.name end)
  local affil_blocks = {}
  for i, affil in ipairs(affiliations) do
    table.insert(affil_blocks,
      panlunatic.Superscript(panlunatic.Str(tostring(i))) ..
      panlunatic.Space() ..
      affil.name
    )
  end
  io.stderr:write(tostring(#affiliations))
  io.stderr:write(tostring(#affil_blocks))

  body = panlunatic.Para(table.concat(affil_blocks, panlunatic.LineBreak())) ..
    panlunatic.Blocksep() .. body

  return panlunatic.Doc(body, meta, variables)
end

function Cite (c, cs)
  for i = 1, #cs do
    _, cs[i].citationId = cito.cito_components(cs[i].citationId)
  end
  return panlunatic.Cite(c, cs)
end
