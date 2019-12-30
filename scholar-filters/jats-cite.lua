function Cite (cite)
  for _, c in pairs(cite.citations) do
    c.mode = 'NormalCitation'
  end
  return cite
end
