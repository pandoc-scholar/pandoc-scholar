--
-- jsonld.lua
--
-- Copyright (c) 2017 Albert Krewinkel, Robert Winkler
--
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU public license version 2 or later.
-- See the LICENSE file for details.

function Doc (body, meta, variables)
  return meta.jsonld
end

setmetatable(_G, {__index = function () return function () return '' end end})
