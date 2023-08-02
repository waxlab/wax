-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local waxp = require 'waxp'

local etc = {}

local spec = {
  module =
    function(key, val)
      if not val.src then error('Missing src for module '..key, 3) end
      if type(val.src) == 'string' then val.src = { val.src } end
      if type(val.src) ~= 'table' then
        error('Module src must be string or list for '..key, 3)
      end
      return key, val
    end,

  luaver =
    function (val)
      if type(val) == 'string' then val = {val} end
      if type(val) ~= 'table' then
        error('lua entry must be a string or a list')
      end
      for i,ver in ipairs(val) do
        if type(ver) ~= 'string' then
          error('lua entry must be a string or a list of strings',2)
        end
        val[i] = waxp.isluaver(ver, 3)
      end
      return val
    end
}


function etc.project(project)
  local cfx = require 'wax.xconf'
  local conffile = waxp.workdir .. '/etc/' .. project .. '.lua'
  return cfx.loadfile(conffile, spec)
end


return etc
