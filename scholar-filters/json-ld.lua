-- json-ld.lua: add a JSON-LD metadata field describing the document.
--
-- Copyright (c) 2017-2021 Albert Krewinkel
--
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU public license version 2 or later.
-- See the LICENSE file for details.
local SCRIPT_DIR = PANDOC_SCRIPT_FILE:gsub('/[^/]*$', '')

package.path =  SCRIPT_DIR .. '/?.lua;' .. package.path

local json = require "dkjson"
local List = require 'pandoc.List'

local function stringify(x)
  if x == nil then
    return nil
  elseif type(x) == 'string' then
    return x
  end
  return pandoc.utils.stringify(x)
end

local function Organizations(orgs)
  local orgs_json = {}
  for i, org in ipairs(orgs) do
    orgs_json[i] = {
      ["@type"] = "Organization",
      ["name"]  = org.name and stringify(org.name),
      ['url']   = org.url and stringify(org.url),
    }
  end
  return orgs_json
end

local function Authors(authors)
  local authors_json = pandoc.MetaList{}
  for i, author in ipairs(authors) do
    authors_json[i] = {
      ['@type']       = "Person",
      ['@id']         = authors[i].orcid and
                          ("https://orcid.org/" .. stringify(authors[i].orcid)),
      ["name"]        = author.name and stringify(author.name),
      ["affiliation"] = author.institute and Organizations(author.institute),
      ['email']       = author.email and stringify(author.email),
      ['url']         = author.url and stringify(author.url),
    }
  end
  return authors_json
end

local function Cito (bibjson, cites_by_cito_property)
  function find_citation(id)
    -- sloooow
    for i = 1, #bibjson do
      if bibjson[i].id == id then
        return bibjson[i]
      end
    end
  end

  local result = {}
  local bibentry, citation_ld
  for citation_type, typed_citation_ids in pairs(cites_by_cito_property) do
    for i = 1, #typed_citation_ids do
      bibentry = find_citation(typed_citation_ids[i])
      if bibentry and bibentry.DOI then
        citation_ld = {
          ["@id"] = "http://dx.doi.org/" .. bibentry.DOI
        }
        cito_type_str = "cito:" .. citation_type
        if not result[cito_type_str] then
          result[cito_type_str] = {}
        end
        table.insert(result[cito_type_str], citation_ld)
      end
    end
  end
  return result
end

local function Citations (bibjson, citation_ids)
  function find_citation(id)
    -- sloooow
    for i = 1, #bibjson do
      if bibjson[i].id == id then
        return bibjson[i]
      end
    end
  end

  function CitationSchema(record)
    local type
    if record.type == "report" then
      type = "Report"
    elseif record.type == "article-journal" then
      type = "ScholarlyArticle"
    else
      type = "Article"
    end

    local authors = {}
    if record.author then
      for i = 1, #record.author do
        local name = {
          record.author[i].family,
          record.author[i].given
        }
        authors[i] = {
          name = table.concat(name, ", ")
        }
      end
    end

    return {
      ["@context"] = {
        ["@vocab"]    = "http://schema.org/",
        ["title"]     = "headline",
        ["page"]      = "pagination",
        ["date"]      = "datePublished",
        ["publisher"] = "publisher",
        ["author"]    = "author",
      },
      ["@type"]     = type,
      ["@id"]       = record.DOI and ("http://dx.doi.org/" .. record.DOI),
      ["title"]     = record.title,
      ["author"]    = Authors(authors),
      ["date"]      = record.issued and
        record.issued["date-parts"] and
        table.concat(record.issued["date-parts"][1], "-"),
      ["publisher"] = record.publisher and
        { ["@type"] = "Organization", ["name"] = record.publisher },
      ["page"]      = record.page,
    }
  end

  local res = {}
  for cit_id, _ in pairs(citation_ids) do
    local citation_record = find_citation(cit_id)
    if citation_record then
      res[#res + 1] = CitationSchema(citation_record)
    end
  end
  return res
end

function json_ld (meta)
  local default_image = "https://upload.wikimedia.org/wikipedia/commons/f/fa/Globe.svg"
  local accessible_for_free
  if meta.accessible_for_free ~= nil then
    accessible_for_free = meta.accessible_for_free
  else
    accessible_for_free = true
  end
  local context = {
    ["@vocab"]    = "http://schema.org/",
    ["cito"]      = "http://purl.org/spar/cito/",
    ["author"]    = "author",
    ["name"]      = "name",
    ["title"]     = "headline",
    ["subtitle"]  = "alternativeTitle",
    ["publisher"] = "publisher",
    ["date"]      = "datePublished",
    ["isFree"]    = accessible_for_free and "isAccessibleForFree" or nil,
    ["image"]     = "image",
    ["citation"]  = "citation",
  }

  local citation_ids = {}
  for _, ids in pairs(meta.cito_cites) do
    for _, id in ipairs(ids) do citation_ids[id] = true end
  end
  local result = {
    ["@context"]  = context,
    ["@type"]     = "ScholarlyArticle",
    ["author"]    = Authors(meta.author),
    ["name"]      = stringify(meta.title),
    ["title"]     = stringify(meta.title),
    ["subtitle"]  = meta.subtitle and stringify(meta.subtitle),
    ["date"]      = meta.date and stringify(meta.date) or os.date("%Y-%m-%d"),
    -- -- ["image"]     = meta.image or default_image,
    ["isFree"]    = accessible_for_free,
    ["citation"]  = Citations(meta.bibliography_records, citation_ids),
  }
  for k, v in pairs(Cito(meta.bibliography_records, meta.cito_cites)) do
    result[k] = v
  end
  return result
end

local function bibliography(bibfilename)
  if not bibfilename or bibfilename == '' then
    return {}
  end
  local bibfile = io.popen("pandoc-citeproc --bib2json " .. bibfilename, "r")
  local jsonstr = bibfile:read("*a")
  bibfile:close()
  return json.decode(jsonstr)
end

local function institute_resolver (institutes)
  return function (inst_idx)
    return institutes[tonumber(stringify(inst_idx))]
  end
end

function Meta (meta)
  local function clone (obj)
    local result = {}
    for k, v in pairs(obj) do result[k] = v end
    return result
  end
  local metadata = clone(meta)

  local resolve_institute = function (idx)
    return meta.institute[tonumber(idx)]
  end
  local tmp_authors = {}
  for i, author_orig in ipairs(meta.author) do
    local author = clone(author_orig)
    if author.institute then
      author.institute = List.map(author.institute, resolve_institute)
    end
    tmp_authors[i] = author
  end
  metadata.author = tmp_authors

  local bib = pandoc.utils.stringify(meta.bibliography)
  metadata.bibliography_records = bibliography(bib)
  local jsonld_object = json_ld(metadata)
  meta.jsonld = json.encode(jsonld_object)

  return meta
end
