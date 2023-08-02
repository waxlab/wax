local table_insert, table_remove = table.insert, table.remove


local
function err(lvl, msg, ...)
  if lvl then
    error(msg:format(...), lvl > 0 and lvl + 2 or lvl)
  end
  return nil, msg:format(...)
end


local
function oas_pairs(t)
  local i,d=0,rawget(t, '__data')
  return function() local k=d[i] return k, d[k] end
end


local
function oas_ipairs(t)
  return ipairs(rawget(t,'__data'))
end


local
function oas_insert(t, k, v, i, l)
  local d = rawget(t, '__data')
  if k == nil then err(l, 'attempt to use nil as record key') end
  if type(k) == 'number' then err(l, 'attemt to use number as record key') end
  if d[k] ~= nil then return err(l, '%q already exists', k) end
  if i then table_insert(d,i,k) else table.insert(d,k) end
  d[k] = v
  return true
end


local
function oas_call(t, k, v)
  if k == nil then return #(rawget(t, '__data')) end
  if v == nil then return rawget(t, '__data')[k] end
  if type(k) == 'number' then
    return error('attempt to use number as ordered record key', 2)
  end
  local _, emsg = table_insert(t, k, v)
  return emsg and err(2, emsg) or true
end


local
function oas_index(t, k)
  return rawget(t, '__data')[k]
end


local
function oas_remove(t, k)
  local d = rawget(t, '__data')
  if k == nil or type(k) == 'number' then
    d[k]=nil
    return table_remove(d, k)
  else
    for i, ik in ipairs(d) do
      if ik == k then
        d[k] = nil
        return table_remove(d, i)
      end
    end
  end
end

local
function oas_unwrap(t)
  return rawget(t,'__data')
end


local OrderedRecord = {
  __name = 'OrderedRecord',
  __call     = oas_call,
  __pairs    = oas_pairs,
  __newindex = oas_insert,
  index      = oas_index,
  ipairs     = oas_ipairs,
  pairs      = oas_pairs,
  insert     = oas_insert,
  remove     = oas_remove,
  unwrap     = oas_unwrap,
}

OrderedRecord.__index = OrderedRecord

local
function oas_new()
  return setmetatable({__data={}}, OrderedRecord)
end

return {
  new    = oas_new,
  index  = oas_index,
  ipairs = oas_ipairs,
  pairs  = oas_pairs,
  insert = oas_insert,
  remove = oas_remove,
  unwrap = oas_unwrap,
}
