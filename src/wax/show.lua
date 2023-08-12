-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local fmt   = string.format
local cat   = table.concat
local tpair = '%s%s = %s,\n'
local ttbl  = '{\n%s%s}'
local key   = '[%s]'
local tab   = '  '

local dump


function dump(what, refs, lvl, path)
  local t = type(what)
  local ref

  if t == 'string' then
    if path then
      return fmt('%q',what)
    elseif what:match('^[^%l_][%w_]*$') then
      return fmt('[%q]',what)
    else
      return what
    end

  elseif t == 'number' or t == 'boolean' then
    return path and tostring(what) or key:format(tostring(what))
  end

  if refs[what] then return '@'..refs[what] end

  if not path then
    ref = #refs+1
    refs[what] = ref
  else
    refs[what] = path
  end

  local res,s = {},1

  if t == 'table' then
    for k, v in pairs(what) do
      k = dump(k, refs, 2)
      v = dump(v, refs, lvl+1, (ref and '@'..ref or path)..'.'..k)
      res[s], s = tpair:format(tab:rep(lvl), k, v) , s+1
    end
    res = ttbl:format(cat(res), tab:rep(lvl-1))
  else
    res = tostring(what)
  end
  if ref then
    refs[ref], res = res, '@'..ref
  end
  return res
end


return function(what, out)
  out = out or io.stdout
  local refs = {}
  local res = dump(what, refs, 1,'')

  out:write '\nData = '
  out:write (res)
  if #refs > 0 then
    print '\n\nReferences:'
    for i, v in ipairs(refs) do
      out:write '  @'
      out:write (i)
      out:write ' = '
      out:write (v)
    end
  end
  out:write '\n'
end

