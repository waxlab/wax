-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local
wax_argerror,
wax_from,
wax_ismainmodule,
wax_locals, _locals_mt,
wax_script,
wax_similar,
wax_tostring,
wax_tochunk,
wax_setfenv,
wax_load,
wax_loadfile,
wax_luaver

local unpack = table.unpack or unpack

local fs_realpath = require 'wax.fs'.realpath

function wax_script()
  local s = debug.getinfo(2,'S')
  if s then return fs_realpath(s.short_src) end
  return nil
end


function wax_ismainmodule()
  return arg[0] == debug.getinfo(2).short_src
end


function wax_locals()
  local _ENV    = _ENV or _G
  local _ENV_MT = getmetatable(_ENV)

  if not _locals_mt then
    _locals_mt = {
      __newindex = function(_, name)
        local msg = 'variable %q declared without local keyword at %s:%d'
        local info = debug.getinfo(2)
        error( msg:format(name, info.source, info.currentline), 2)
      end
    }
  end

  if _ENV_MT == _locals_mt then return true end

  if not _ENV_MT then
    setmetatable(_ENV,_locals_mt)
    return true
  end

  return nil, 'Other metatable is already set for _ENV or _G'
end


function wax_argerror(n,exp)
  local fname = debug.getinfo(2,'n').name
  error(("bad argument #%d to '%s' (%s expected)"):format(n,fname or '?',exp),3)
end


function wax_from(src, ...)
  local srctype = type(src)

  if srctype == 'string' then
    src     = require(src)
    srctype = type(src)
  end

  if srctype == 'table' then
    local t = {...}
    for n,v in pairs(t) do t[n] = src[v] end
    return (table.unpack or unpack)(t)
  end

  wax_argerror(1,"table or module name")
end

do -- wax_similar
  local metatable = getmetatable
  local pairs = pairs
  local check
  function wax_similar(a,b)
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
      if wax_similar(v,b[k])
        then m[k] = 1
        else return false
      end
    end

    for k,v in pairs(b) do
      if not m[k] and not wax_similar(v, a[k])
        then return false
      end
    end

    return true
  end
end

do -- wax_tostring and wax_tochunk
  local cat,fmt = table.concat, string.format
  local validkey = { string='[%q]', number='[%s]', boolean='[%s]' }
  local validval = { string='%q', number='%s', boolean='%s', table=1 }


  function wax_tostring(data)
    local tpl   = {0,'=',0} -- reusable template table
    local acc,i = {},1      -- accumulator and its index pos
    local ktype, kfmt ,vfmt

    for _,v in ipairs(data) do
      vfmt = validval[type(v)]

      if vfmt then
        acc[i] = vfmt == 1
             and wax_tostring(v)
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
               and wax_tostring(v)
                or fmt(vfmt, tostring(v))
          acc[i],i = cat(tpl), i+1
        end

      end
    end
    tpl[1], tpl[2], tpl[3] = '{', cat(acc,','), '}'
    return cat(tpl)
  end

  function wax_tochunk(data)
    local kt, vfmt
    local tpl   = {0,'=',0} -- reusable template table
    local acc,i = {},1      -- accumulator and its index pos
    for k,v in pairs(data) do
      kt = type(k)
      if kt == 'string' and k:match('^[%l%d_]+$') then
        vfmt = validval[type(v)]
        if vfmt then
          tpl[1] = k
          tpl[3] = vfmt == 1 and wax_tostring(v) or fmt(vfmt,v)
          acc[i], i = cat(tpl), i+1
        end
      end
    end
    return cat(acc,'\n')
  end
end

wax_luaver = _VERSION:gsub('.* ([%d.]*)$','%1')


-- compatibility functions
-- wax_load, wax_loadfile, wax_setfenv
if wax_luaver == '5.1' then

  wax_setfenv = setfenv

  function wax_load(chunk, envt)
    local fn, err = loadstring(chunk, nil)
    if not fn then return fn, err end
    if envt then setfenv(fn, envt) end
    return fn
  end

  function wax_loadfile(filename, envt)
    local fn, err = loadfile(filename)
    if err then return fn, err end
    if envt then return setfenv(fn, envt) end
    return fn
  end

else

  function wax_setfenv(fn, envt)
    debug.upvaluejoin(fn, 1, function() return envt end, 1)
    return fn
  end

  function wax_load(chunk, envt)
    return load(chunk, nil, 't', envt)
  end

  function wax_loadfile(f, e)
    return loadfile(f, 't', e)
  end

end




return (require "wax.lazy")("wax", {
  argerror     = wax_argerror,
  from         = wax_from,
  ismainmodule = wax_ismainmodule,
  locals       = wax_locals,
  script       = wax_script,
  similar      = wax_similar,
  tostring     = wax_tostring,
  tochunk      = wax_tochunk,
  luaver       = wax_luaver,
  load         = wax_load,
  loadfile     = wax_loadfile,
  setfenv      = wax_setfenv,
})
