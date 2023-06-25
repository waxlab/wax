-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local
collect,
kstr


local cat = table.concat
local wrt = io.stdout.write
local fmt = string.format
local fnd = string.find
local rep = string.rep
local sub = string.sub
local tostring, type, pairs
    = tostring, type, pairs


function collect(data, write, path, p, refs)
  local t = type(data)
  if t == 'string' then
    return write(fmt('%q', data))
  elseif t == 'number' or t == 'boolean' then
    return write(tostring(data))
  elseif t ~= 'table' then
    return write(tostring(data))
  end

  -- From tables --
  local r = tostring(data)
  if not refs[r] then
    refs[r] = cat(path, '', 1, p)
    write '{\n'
    local indent = rep("  ", p)
    for key, val in pairs(data) do
      write (indent) ( kstr (key, path, p+1) ) ' = '
      collect(val, write, path, p+1, refs)
      write ',\n'
    end
    write (sub(indent, 1,-3)) '}'
  else
    write (refs[r])
  end
end


function kstr(data, path, p)
  local result
  if type(data) ~= 'string' then
    result  = fmt('[%s]', tostring(data))
    path[p] = result
  elseif fnd(data, '%W') then
    result  = fmt('[%q]',data)
    path[p] = result
  else
    result  = tostring(data)
    path[p] = '.'..result
  end
  return result
end


return function(data, out)
  local write
  out = out or io.stdout
  function write (d) wrt(out,d) return write end
  collect(data, write, {"@"}, 1, {})
  write '\n'
  out:flush()
end
