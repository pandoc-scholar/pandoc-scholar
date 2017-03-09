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
