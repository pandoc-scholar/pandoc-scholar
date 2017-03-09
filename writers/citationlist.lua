-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU public license version 2 or later.
-- See the LICENSE file for details.

local citation_ids = {}
function Doc(body, meta, vars)
  local res = {}; for cid, _ in pairs(citation_ids) do res[#res + 1] = cid end
  return table.concat(res, "\n")
end
function Cite(c, cs)
  for i = 1, #cs do citation_ids[cs[i].citationId] = true end
  return ''
end
setmetatable(_G, {__index = function() return function() return "" end end})
