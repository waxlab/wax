-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--[[
=========
waxp.help
=========

This module contains a very basic way to find doc strings on files and modules.
It is intended as a fast way to retrieve information when directly using waxp
functionalities.

--]]

local help = {}
local wax = require 'wax'
local waxp = require 'waxp'
local out=io.stdout

--[[
  $ waxp.help.main(module:string)

  Get doc strings from module. The ``module`` argument can be either
  a file name or a module name as used on 'require'
--]]
function help.main(identifier)
  local file
  if not identifier:find('/') then
    file = wax.searchpath(identifier, package.path)
  end
  if not file then
    file = waxp.isfile(identifier)
  end
  local f = io.open(file,'r')
  local isdoc = false
  local pad, content, p, _

  out:write('\n\n')
  while true do
    local line = f:read()
    if not line then
      out:write '\n'
      return f:close()
    end

    if isdoc then
      _, content = line:match('^('..pad..')(.*)$')
      if content then
        if content:match '^%-%-%]%]' then
          isdoc, pad = false, nil
        else
          if not content:match('^%s*%$') then
            out:write('  ')
          end
          out:write (content)
        end
        out:write '\n'
      end
    else
      p = line:match('^(%s*)%-%-%[%[')
      if p then isdoc, pad = true, p end
    end
    out:write('\n\n')
  end
end


return help
