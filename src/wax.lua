local wax = {}
do
  setmetatable(_G, {
    __index = function() return nil end,
    __newindex = function(_,n) error(('cant set global %q'):format(n),2) end
  })
end

--@ wax.similar()
do
  local similar, simtable

  function simtable(a,b)
    local m = {}
    if getmetatable(a) ~= getmetatable(b)
      then return false
    end
    for k,v in pairs(a) do
      if not similar(v,b[k]) then return false end
      m[k]=1
    end
    for k,v in pairs(b) do
      if not m[k] and not similar(v, a[k]) then return false end
    end
    return true
  end


  function similar(a,b)
    if a == b           then return true          end

    local ta,tb = type(a),type(b)
    if ta ~= tb         then return false         end
    if ta == 'table'    then return simtable(a,b) end
    return false
  end
  wax.similar = similar
end

return wax
