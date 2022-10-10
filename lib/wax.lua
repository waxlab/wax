local wax = {}
local luaver = _VERSION:gsub('.* ([%d.]*)$','%1')


-- TODO: To be moved to wax.test.almostEqual
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

if luaver == '5.1' then

  wax.setfenv = setfenv

  function wax.load(chunk, envt)
    local fn, err = loadstring(chunk, nil)
    if not fn then return fn, err end
    if envt then setfenv(fn, envt) end
    return fn
  end

  function wax.loadfile(filename, envt)
    local fn, err = loadfile(filename)
    if err then return fn, err end
    if envt then return setfenv(fn, envt) end
    return fn
  end

else

  function wax.setfenv(fn, envt)
    debug.upvaluejoin(fn, 1, function() return envt end, 1)
    return fn
  end

  function wax.load(chunk, envt)
    return load(chunk, nil, 't', envt)
  end

  function wax.loadfile(f, e)
    return loadfile(f, 't', e)
  end

end


function wax.scriptfile()
  local realpath = require 'wax.fs'.realpath
  local s = debug.getinfo(2,'S')
  if s then return realpath(s.short_src) end
  return nil
end

return wax
