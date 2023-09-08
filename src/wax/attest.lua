local cat = table.concat
local pop = table.remove
local push = table.insert
local lua52p = _VERSION ~= 'Lua 5.1' or nil

local Tree = {

  node = function(S)
    return S._refs[S._len]
  end,

  test = function(S,a,b,msg)
    if a ~= b then
      a = (type(a) == 'string' and ('%q'):format(a))
        or (a == nil and 'nil')
        or tostring(a)
      b = (type(b) == 'string' and ('%q'):format(b))
        or (b == nil and 'nil')
        or tostring(b)
      error(
        ("\n%s %s:\n  Expected: %s\n  Found:    %s\n")
          :format(msg, cat(S._path,'.'), a, b)
        , lua52p and 2 or 3
      )
    end
    return S
  end,

  key = function(S, key)
    local node = S:node()
    local t = type(node)
    if t == 'table' or t == 'userdata' then
      push(S._refs, node[key])
      push(S._path, key)
      S._len = #S._path
      return S
    end
    error( cat(S._path,'.')..' is not a tree', 2)
  end,

  isTable = function(S, expi, expk)
    S:test('table', type(S:node()), 'Type of')
    if expi then
      S:test(expi, #S:node(), 'List length')
    end
    if expk then
      local val=0
      for _ in pairs(S:node()) do val=val+1 end
      return S:test(expk, val, 'Record count')
    end
    return S
  end,

  len = function(S, expi, expk)
    S:test(expi, #S:node(), 'List length')
    if expk then
      local val=0
      for _ in pairs(S:node()) do val=val+1 end
      return S:test(expk, val, 'Record count')
    end
    return S
  end,

  eq = function(S, expected)
    return S:test(expected, S:node(), 'Equality of')
  end,

  type = function(S, expected)
    return S:test(expected, type(S:node()), 'Type of')
  end,

  back = function(S)
    if S._len > 0 then
      pop(S._refs)
      pop(S._path)
      S._len = S._len - 1
      return S
    end
    error('Cannot go before the tree root',2)
  end,
}

Tree.__index = Tree

return function(tree)
  local t = type(tree)

  if t=='table' or t=='userdata' then
    local S = {
      _path = {},
      _refs = {[0]=tree},
      _len  = 0
    }
    return setmetatable(S,Tree)
  end
  error('Attempt to use '..type(tree)..' as tree',2)
end
