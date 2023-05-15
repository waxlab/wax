-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local mt = {
  __index=function(self, item)
    local R = require( self.__name .. '.' .. item )
    self[item] = R
    return R
  end
}

return function (modname, mod)
  if type(mod) == 'string' then mod = require(mod) end
  if mod.__name then
    error( ("%s is already lazy loadable"):format(mod.__name) )
  end

  mod.__name = modname
  return setmetatable(mod, mt)
end
