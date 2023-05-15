-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local
  parse, _parse_fold

local _unpack = table.unpack or unpack


function parse(a, index)
  local t = {opt={}, arg={}}
  return _parse_fold(t, a or _G.arg, index or 1)
end

function _parse_fold(t, arg, p, o)
  local a = arg[p]

  if not a then return t end
  if a:find('^%-%-') then
    o = a:sub(3)
    if o ~= '' then t.opt[o] = t.opt[o] or {} end
  elseif o and o ~= '' then
    t.opt[o][#t.opt[o] + 1],o = arg[p]
    o = nil
  else
    t.arg, p = {_unpack(arg,p)}, -1000
  end
  return _parse_fold(t, arg, p+1, o)
end

return {
  parse = parse,
}
