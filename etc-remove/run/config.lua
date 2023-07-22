-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local config = {}
local util = require 'etc.run.util'

if _VERSION == "Lua 5.1" then
  function _load(str)
    local t = {}
    local fn, err = loadstring(str, nil)
    if err then return nil, err end
    setfenv(fn,t)()
    return t
  end
else
  local uvj = debug.upvaluejoin
  function _load(str)
    local t = {}
    local fn, err = load(str, nil, 't')
    if err then return nil, err end

    uvj(fn,1,function() return t end, 1)
    fn()
    return t
  end
end


local
function readconf(file)
  local f = io.open(file, 'r')
  if not f then
    util.die('file %q not found',file)
  end
  local cfg, err = _load( f:read('*a') )
  f:close()

  if err then
    util.die("Couldn't load %s %q",file,err)
  end

  local modules = cfg.modules
  for pkgname, pkgitems in pairs(modules) do
    local _type

    if type(pkgitems) ~= 'table' then
      util.die("Package %q must be a table", pkg)
    end

    for modname, modcfg in pairs(pkgitems) do
      -- Expands simplified entries
      if type(modcfg) == 'string' then
        modcfg = { modcfg }
      end

      if type(modcfg) ~= 'table' then
        util.die('%s.%s: invalid config', pkgname, modname)
      end
      modcfg.type = modcfg[#modcfg]:match('%.([^.]+)$')
      modcfg.name = pkgname..'.'..modname
      modules[pkgname][modname] = modcfg
    end
  end
  return cfg
end

local configfile = 'etc/config.lua'
config = readconf(configfile)
assert(config.rockspec, 'rockspec entry not found in config.lua')
config.rockspec = ('etc/rockspec/%s'):format(config.rockspec)

--[[
function config:getlmod(m)
  local r = {}
  for name, file in pairs(m) do
    if type(file) == 'table' and file:match('%.lua$') then
      r[m..'.'..name] = file
    end
  end



  return r;
end

function config:getcmod(package)
  local r, rpos = {}, 1
  local packpath = package:gsub('%.','/')
  print("GETTING C MOD PACKAGE", package)

  for mod, conf in pairs(self.modules[package]) do
    mod = packpath..'/'..mod
    if type(conf) == 'string' then
      if conf:match('%.c$') then
        r[rpos], rpos = { src={conf}, mod=mod }, rpos+1
      end
    elseif conf[#conf]:match('%.c$') then
      local src={}
      for i,s in ipairs(conf) do src[i] = s end
      r[rpos], rpos = {src=src, mod=mod, lflags=conf.lflags}, rpos+1
    end
  end
  return r
end
]]

return config
