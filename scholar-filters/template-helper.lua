--[[
template-helper: generate meta fields to be used in templates.

Copyright © 2017–2021 Albert Krewinkel

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
]]

local List = require 'pandoc.List'

function Meta (meta)
  local function resolve_institute (idx)
    return meta.institute[tonumber(idx)]
  end

  for i, author in ipairs(meta.author) do
    local institute_indices = List:new(author.institute)
    local institutes = institute_indices:map(resolve_institute)
    author.institute_indices = institute_indices
    author.institute = institutes
    meta.has_equal_contributors = meta.has_equal_contributors
      or author.equal_contributor
    meta.has_correspondence = meta.has_correspondence
      or author.correspondence and author.email
  end
  -- helper attributes
  if #meta.author > 0 then
    meta.author[1].first = true
    meta.author[#meta.author].last = true
  end

  for i, institute in ipairs(meta.institute) do
    institute.index = tostring(i)
  end

  return meta
end

