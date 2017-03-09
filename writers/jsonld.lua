--
-- jsonld.lua
--
-- Copyright (c) 2017 Albert Krewinkel, Robert Winkler
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the ISC license. See LICENSE for details.

package.path = package.path .. ";scholarly-metadata/?.lua"

local json = require "dkjson"
local cito = require "cito"
local scholarlyjsonld = require "scholarlyjsonld"
local scholarlymeta = require "scholarlymeta"

scholarlymeta.options.json_values = false

local bibliography = nil
local citation_ids = {}
local citations_by_property = {}

local function bibliography(bibfilename)
  if not bibfilename then
    return {}
  end
  local bibfile = io.popen("pandoc-citeproc --bib2json " .. bibfilename, "r")
  local jsonstr = bibfile:read("*a")
  bibfile:close()
  return json.decode(jsonstr)
end

function Doc(body, meta, vars)
  meta.author, meta.institute =
    scholarlymeta.canonicalize_authors()
  meta.citation_ids = citation_ids
  meta.cito_cites = citations_by_property
  meta.bibliography_records = bibliography(meta.bibliography)
  local jsonld = scholarlyjsonld.json_ld(meta)
  return json.encode(jsonld)
end

------- Inlines -------
function Cite(s, cs)
  local cito_prop, cit_id
  for i = 1, #cs do
    cito_prop, cit_id = cito.cito_components(cs[i].citationId)
    citation_ids[cit_id] = true
    if not citations_by_property[cito_prop] then
      citations_by_property[cito_prop] = {}
    end
    table.insert(citations_by_property[cito_prop], cit_id)
  end
  return s
end

local meta = {__index = function() return function() return "" end end }
setmetatable(_G, meta)

