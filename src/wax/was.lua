-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local sim, _simr

local _getmt = getmetatable
local _pairs = pairs

function sim(a,b)
  if a == b then return true end

  local ta,tb = type(a),type(b)
  if ta ~= tb      then return false      end
  if ta == 'table' then return _simr(a,b) end

  return false
end

function _simr(a,b) -- recursive check
  if _getmt(a) ~= _getmt(b) then return false end

  local m = {}
  for k,v in _pairs(a) do
    if sim(v,b[k])
      then m[k] = 1
      else return false
    end
  end

  for k,v in _pairs(b) do
    if not m[k] and not sim(v, a[k])
      then return false
    end
  end

  return true
end

return {
  similar = sim
}
