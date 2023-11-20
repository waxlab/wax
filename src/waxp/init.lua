-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors


--[[
  $ waxp.isLuaVersion(value:string)

  Checks the value refers to a valid accepted Lua version.
--]]
local function isluaver(val, lvl)
  return
    val:match '^5%.[1234]$'
    or error(('Invalid Lua version: %q'):format(val), (lvl or 0)+1)
end
--[[
  $ waxp.isFile(filename:string)

  Wrapper around ``waxp.isfile``
--]]
local function isfile(filename, lvl)
  local f = io.open(filename,'r')
  if f then
    f:close()
    return true
  end
  error(('File not found: %q'):format(filename), lvl and (lvl or 0)+1)
end

--[[
  $ waxp.targetmodule(name: str) proj:str, mod:str, part:str

  Parse the target module to work with
--]]
local function targetmodule(args)
  local tgt, pkg, mod, luatgt, cfg
  tgt = args[1]

  if not tgt then
    io.stderr:write('Missing target module name\n')
    os.exit(1)
  end
  pkg, mod = tgt:match '^(%a[%w%-]+)%.(.*)$'
  pkg = pkg and pkg:match '^(%a%w+)' or tgt
  mod = mod and tgt or pkg

  local cfg, err = require 'waxp.etc'.project(pkg)

  if not cfg then
    io.stderr:write('Config error: '..err..'\n')
    os.exit(1)
  end

  luatgt = args.luaver or cfg.luaver

  return pkg, mod, luatgt, cfg
end

local waxp = {
  isluaver = isluaver,
  isfile = isfile,
  targetmodule = targetmodule,
  buildargs = {
    { 'luaver',  'l', '+', desc = 'Use specific Lua version on tests'},
    { 'debug',   nil, '-', desc = 'Enable more verbosity on tests',
                           default=false },
    { 'incdir',  'I', '+', desc = 'Add directory to compiler include path' },
    { 'libdir',  'L', '+', desc = 'Add directory to the library link path' },
    { 'help',    nil, '-', desc = 'Show this help' },
    { 'verbose', 'V', '-', desc = 'More verbosity' },
  }
}


--[[
$ waxp.selfdir : string
Waxp folder used to waxp find its own modules.
--]]
waxp.selfdir = arg[0]:gsub('[^/]*$',''):gsub('^$','./')

-- Adds the wax project source path before the default package.path
package.path =
  ('./src/?.lua;./src/?/init.lua;%ssrc/?.lua;%ssrc/?/init.lua;')
    : format(waxp.selfdir, waxp.selfdir)
  ..package.path

local sh = require 'waxp.sh'


--[[
$ waxp.luaver(strver: string) : ver, sver, luanum, maj, min :number
Extract different representations from the Lua version string. Example
for ``waxp.luaver("5.4")``:
* ``ver`` : 5.4
* ``sver``: 54
* ``num`` : 504
* ``maj`` : 5
* ``min`` : 4
--]]
function waxp.luaver(ver)
  local maj, min = ver:match '^(%d+)%.(%d)$'
  if not maj and min then
    return nil
  end
  ver = tonumber(ver)
  local sver = maj..min
  local num = maj*100+min
  return ver, sver, num, maj, min
end

--[[
$ waxp.luabin(ver:string)
Get the binary for Lua from the path that matches the version
--]]
local _lua = {}
function waxp.luabin(ver)
  if _lua[ver] == nil then
    ver = isluaver(ver)
    _lua[ver] = sh.whereis('lua'..ver)
             or sh.whereis('lua'..ver:gsub('%.',''))
             or false
  end
  return _lua[ver]
end

--[[
$ waxp.workdir : string
Current working dir, where the project(s) are found
--]]
waxp.workdir = sh.rexec('realpath .')[1]

--[[
$ waxp.help(modname: string)
(Temporary!) shows module docstrings.
--]]
do
  local modopen
  function modopen(modname)
    local m = modname:gsub('%.','/')
    for p in package.path:gmatch('([^;]+)') do
      local f = io.open((p:gsub('%?',m)))
      if f then return f end
    end
    return nil, ('Module %q nof found in path'):format(modname)
  end

  function waxp.help(mod)
    local f = mod
      and assert(modopen(mod))
      or  assert(io.open(arg[0]))
    local line = f:read()
    while line do
      local t,_,txt = line:match('^%-%-([|${}])(%s?)(.*)')
      if t then
        if t == '$' then
          print() print(txt,'\n')
        else
          print('    '..txt)
        end
      end
      line = f:read()
    end
    f:close()
  end
end


return require 'wax'.lazy('waxp',waxp)
