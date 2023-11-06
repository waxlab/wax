local table_insert, table_remove = table.insert, table.remove


local function err(lvl, msg, ...)
  if lvl then
    error(msg:format(...), lvl > 0 and lvl + 2 or lvl)
  end
  return nil, msg:format(...)
end


local function rec_pairs(t)
  local i,d=0,rawget(t, '__data')
  return function() i=i+1 return d[i], d[d[i]] end
end


local function rec_ipairs(t)
  return ipairs(rawget(t,'__data'))
end


local function rec_insert(t, k, v, i, l)
  local d = rawget(t, '__data')
  if k == nil then err(l, 'attempt to use nil as record key') end
  if type(k) == 'number' then err(l, 'only strings can be used as record key') end
  if d[k] ~= nil then return err(l, '%q already exists', k) end
  if i then table_insert(d,i,k) else table.insert(d,k) end
  d[k] = v
  return true
end


local function rec_index(t, k)
  return rawget(t, '__data')[k]
end


local function rec_remove(t, k)
  local d = rawget(t, '__data')
  if k == nil then return end
  if type(k) == 'number' then
    d[d[k]] = nil
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

local function rec_unwrap(t)
  return rawget(t,'__data')
end

local function rec_concat(t, ...)
  return table.concat(t:unwrap(), ...)
end

local function rec_length(t)
  return #rawget(t,'__data')
end

local IndexedRecord = {
  __name = 'IndexedRecord',
  __pairs    = rec_pairs,
  __newindex = rec_insert,
  index      = rec_index,
  ipairs     = rec_ipairs,
  pairs      = rec_pairs,
  insert     = rec_insert,
  remove     = rec_remove,
  concat     = rec_concat,
  unwrap     = rec_unwrap,
  len        = rec_length
}

IndexedRecord.__index = IndexedRecord

return function ()
  return setmetatable({__data={}}, IndexedRecord)
end
