-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local wax = {}

local unpack = table.unpack or unpack

function wax.script()
  local s = debug.getinfo(2,'S')
  if s then return wax.fs.realpath(s.short_src) end
  return nil
end


function wax.ismainmodule()
  return arg[0] == debug.getinfo(2).short_src
end

do
  local mt
  function wax.locals()
    local _ENV    = _ENV or _G
    local _ENV_MT = getmetatable(_ENV)

    if not mt then
      mt = {
        newindex = function(_, name)
          local msg = 'variable %q declared without local keyword at %s:%d'
          local info = debug.getinfo(2)
          error( msg:format(name, info.source, info.currentline), 2)
        end
      }
    end

    if _ENV_MT == mt then return true end

    if not _ENV_MT then
      setmetatable(_ENV,mt)
      return true
    end

    return nil, 'Other metatable is already set for _ENV or _G'
  end
end

local
  function wax_argerror(n,exp)
    local fname = debug.getinfo(2,'n').name
    error(
      ("bad argument #%d to '%s' (%s expected)")
        : format(n,fname or '?',exp)
      , 3
    )
  end
wax.argerror = wax_argerror


function wax.from(src, ...)
  local srctype = type(src)

  if srctype == 'string' then
    src     = require(src)
    srctype = type(src)
  end

  if srctype == 'table' then
    local t = {...}
    for n,v in pairs(t) do
      t[n] = src[v]
          or (src[v] == nil and error('missing member #'..n,2))
    end
    return (table.unpack or unpack)(t)
  end

  wax_argerror(1,"table or module name")
end

-- wax.similar
do
  local metatable = getmetatable
  local pairs = pairs
  local check
  local similar
  function similar(a,b)
    if a == b then return true end

    local ta,tb = type(a),type(b)
    if ta ~= tb      then return false      end
    if ta == 'table' then return check(a,b) end

    return false
  end

  function check(a,b) -- recursive check
    if metatable(a) ~= metatable(b)
      then return false
    end

    local m = {}
    for k,v in pairs(a) do
      if similar(v,b[k])
        then m[k] = 1
        else return false
      end
    end

    for k,v in pairs(b) do
      if not m[k] and not similar(v, a[k])
        then return false
      end
    end

    return true
  end
  wax.similar = similar
end

-- wax.tostring and wax.tochunk
do
  local cat,fmt = table.concat, string.format
  local validkey = { string='[%q]', number='[%s]', boolean='[%s]' }
  local validval = { string='%q', number='%s', boolean='%s', table=1 }
  local tostr

  function tostr(data)
    local tpl   = {0,'=',0} -- reusable template table
    local acc,i = {},1      -- accumulator and its index pos
    local ktype, kfmt ,vfmt

    for _,v in ipairs(data) do
      vfmt = validval[type(v)]

      if vfmt then
        acc[i] = vfmt == 1
             and tostr(v)
              or fmt( vfmt, v )
        i=i+1
      end
    end

    for k,v in pairs(data) do
      ktype = type(k) kfmt = validkey[ktype]
      if kfmt and (ktype ~= 'number' or k < 1 or k % 1 ~= 0) then
        vfmt = validval[type(v)]

        if vfmt then
          tpl[1] = ktype == 'string' and k:match('^[%l%d_]+$')
               and tostring(k)
                or fmt(kfmt, tostring(k))
          tpl[3] = vfmt == 1
               and tostr(v)
                or fmt(vfmt, tostring(v))
          acc[i],i = cat(tpl), i+1
        end

      end
    end
    tpl[1], tpl[2], tpl[3] = '{', cat(acc,','), '}'
    return cat(tpl)
  end
  wax.tostring = tostr

  function wax.tochunk(data)
    local kt, vfmt
    local tpl   = {0,'=',0} -- reusable template table
    local acc,i = {},1      -- accumulator and its index pos
    for k,v in pairs(data) do
      kt = type(k)
      if kt == 'string' and k:match('^[%l%d_]+$') then
        vfmt = validval[type(v)]
        if vfmt then
          tpl[1] = k
          tpl[3] = vfmt == 1 and tostr(v) or fmt(vfmt,v)
          acc[i], i = cat(tpl), i+1
        end
      end
    end
    return cat(acc,'\n')
  end
end


-- compatibility functions & wax.luaver
-- wax.setfenv
-- wax.load
-- wax.loadfile
-- wax.searchpath
do
  local luaver = _VERSION:gsub('.* ([%d.]*)$','%1')
  wax.luaver = luaver

  if luaver == '5.1' then
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

    function wax.searchpath(name, path, sep, rep)
      sep = sep and '%'..sep or '%.'
      rep = rep or '/'
      local reserr, re, file, f, err = {}, 1
      for p in path:gmatch('[^;]+') do
        file = p:gsub('%?', name:gsub(sep,rep))
        f, err = io.open(file,'r')
        if f then
          f:close() return file
        end
        reserr[re], re = ("%s '%s'"):format(err, file), re+1
      end
      return nil, table.concat(reserr, '\n')
    end

    wax.setfenv = setfenv
  else
    function wax.load(chunk, envt)
      return load(chunk, nil, 't', envt)
    end

    function wax.loadfile(f, e)
      return loadfile(f, 't', e)
    end

    wax.searchpath = package.searchpath

    function wax.setfenv(fn, envt)
      debug.upvaluejoin(fn, 1, function() return envt end, 1)
      return fn
    end
  end
end



return (require "wax.lazy")("wax", wax)
--[[
  tostring     = wax_tostring,
}
--]]
