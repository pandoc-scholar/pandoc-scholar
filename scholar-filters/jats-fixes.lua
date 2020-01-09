local List = require 'pandoc.List'

local run_citeproc = function (d, format)
  return pandoc.utils.run_json_filter(d, 'pandoc-citeproc', {format})
end

local is_refs = function (b)
  return b.identifier == 'refs'
end

-- first record the citation link targets, then use those targets
-- to replace faulty targets in the beautified (CSL-adhering)
-- citations.
local cite_link_targets = List:new{}
function record_cite_link_targets (cite)
  local targets = {}
  local record = function (link)
    local tgt = '#ref-' .. pandoc.utils.stringify(link)
    table.insert(targets, tgt)
  end
  pandoc.walk_inline(cite, {Link = record})
  table.insert(cite_link_targets, targets)
  return nil
end

local current_cite = 0
function replace_cite_link_targets (cite)
  current_cite = current_cite + 1
  local current_link = 0
  local targets = cite_link_targets[current_cite]
  local replace = function (link)
    current_link = current_link + 1
    link.target = targets[current_link]
    return link
  end
  return pandoc.walk_inline(cite, {Link = replace})
end

-- Replace citation section, update links
function Pandoc (doc)
  -- Use csl only for citations in the text; the bibliography is
  -- set using the default JATS csl.
  local csl = doc.meta.csl or doc.meta['citation-style']

  doc.meta.csl = doc.meta.jats_csl
  doc.meta['citation-style'] = nil
  doc.meta['link-citations'] = true
  local jats_doc = run_citeproc(doc, 'jats')
  local jats_refs = jats_doc.blocks:find_if(is_refs)
  jats_doc.blocks:map(function (b)
      pandoc.walk_block(b, {Cite = record_cite_link_targets})
      return nil
  end)

  doc.meta.csl = csl
  local pretty_doc = run_citeproc(doc, 'native')
  pretty_doc.blocks = pretty_doc.blocks:map(function (b)
      return pandoc.walk_block(b, {Cite = replace_cite_link_targets})
  end)

  local pretty_refs = pretty_doc.blocks:find_if(is_refs)
  pretty_refs.content = jats_refs.content
  return pretty_doc
end
