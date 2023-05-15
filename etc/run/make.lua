-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local make, help = {},{}
local config = require 'etc.run.config'
local sh = require 'etc.run.sh'
local DEBUG    = os.getenv('DEBUG')    -- debug flags (with gdb and more verbose)
local WAXTFLAG = os.getenv('WAXTFLAG') -- test flags (force -std=gnu89)
local OBJ_EXTENSION = os.getenv 'OBJ_EXTENSION'
local LIB_EXTENSION = os.getenv 'LIB_EXTENSION'
local SINGLE_PACKAGE = os.getenv 'SINGLE_PACKAGE'
local LUA_VERSION = os.getenv 'LUA_VERSION'
local SRCDIR = './src'
local OUTDIR = './out'
local COUTDIR = LUA_VERSION and OUTDIR..'/'..LUA_VERSION or OUTDIR



-----------------------------------------------------------
-- HELPERS ------------------------------------------------
-----------------------------------------------------------

local exec, isdir, getenv
do
  exec = sh.exec

  function isdir(path)
    local p = io.popen(('file -i %q'):format(path),'r')
    if p then
      local mime = p:read('*a')
      mime = mime:gsub('^[^:]*:%s*',''):gsub('%s*;[^;]*$','')
      if mime == 'inode/directory' then
        return true
      end
    end
    return false
  end

  function env(var, def)
    local val = os.getenv(var)
    if not val or val:len() < 1 then
      if not def then error('No env var "'..var..'"',2) end
      val = def
    end
    return val
  end
end

-----------------------------------------------------------
-- INSTALL ------------------------------------------------
-----------------------------------------------------------
do
  local inst = {}
  function make.install ()
    local mods = config.modules

    -- As Luarocks wipes the previous installed files,
    -- we reinstall all ready files, so we can test a single
    -- modules that depends on other modules.
    for _, pkg  in pairs(mods) do
      for _, mod in pairs(pkg) do
        if inst[mod.type] then inst[mod.type](mod) end
      end
    end

    --[[
    if isdir('bin') then
      exec( 'cp -rf%s bin/* %q || :', verbose, env('INST_BINDIR') )
    end

    if config.cbin and #config.cbin > 0 then
      exec( 'cp -rf%s %s/bin/* %q', verbose, COUTDIR, env('INST_BINDIR') )
    end
    ]]
  end
  function inst.lua(mod)
    local src = SRCDIR..'/'..mod[1]
    local dst = env('INST_LUADIR')..'/'..(mod.name:gsub('%.','/'))..'.lua'
    exec('mkdir -p %q', (dst:gsub('/[^/]*$','')))
    exec('cp -rf%s %q %q', DEBUG and 'v' or '', src, dst)
  end

  function inst.c(mod)
    local src = COUTDIR..'/lib/'..mod.name:gsub('%.','/')..'.so'
    local dst = env('INST_LIBDIR')..'/'..(mod.name:gsub('%.','/'))..'.so'
    exec('mkdir -p %q', (dst:gsub('/[^/]*$','')))
    exec('cp -rf%s %q %q', DEBUG and 'v' or '', src, dst)
  end

  help.install = 'Install the Lua files and compiled binaries and libraries'
end

-----------------------------------------------------------
-- CLEAN --------------------------------------------------
-----------------------------------------------------------
function make.clean()
  print("Cleaning project")
  local paths = {
    {within = './',
     './tree', './lua', './luarocks', './lua_modules', './.luarocks', OUTDIR},

    {within = SRCDIR,
     '*.out', '*.o', '*.a', '*.so' }
  }

  local rm = [[find %q -depth -%s '%s' -exec rm -rf {} \;]]
--  local rm = [[find %q %s]]
  for _, loc in ipairs(paths) do
    for _, pat in ipairs(loc) do
      if pat:match("'") then error "Invalid character" end
      local cmd = rm:format(loc.within, pat:find '/' and 'wholename' or 'name', pat)
      os.execute(cmd)
    end
  end
end



-----------------------------------------------------------
-- BUILD --------------------------------------------------
-----------------------------------------------------------
do
  local cc = {}
  function cc.cc(o)
    return o.cc
        or env('CC','gcc')
  end

  -- lflags      = link flags
  -- tflags      = testing flags to enforce code standards
  -- sharedflags = shared object flags
  function cc.tflags() return os.getenv('WAXTFLAG') and '-std=gnu89' or '' end
  function cc.lflags(item) return item.lflags or '' end
  function cc.sharedflag() return env('LIBFLAG', '-shared') end

  -- Compilation flags
  function cc.cflags(mod)
    local debug = os.getenv("CC_DEBUG") and ' -g ' or ''
    local flags
    if mod.flags then
      flags = type(mod.flags) == 'table'
        and debug..table.concat(mod.flags, ' ')
        or  debug..tostring(mod.flags)
    else
      flags = env('CFLAGS', debug)
      flags = flags:gsub('%-O%d+',''):gsub('%-fPIC','')
           .. ' -Wall -Wextra -O3 -fPIC -fdiagnostics-color=always'
    end
    return flags
  end

  function cc.debug(item) return DEBUG and '-g' or '' end


  function cc.src(mod)
    local list, f = {}, nil

    for i,file in ipairs(mod) do
      if file:find('%.%.') then
        util.die('invalid filename: %q', file)
      end
      list[i] = SRCDIR..'/'..file
    end

    return table.concat(list,' ')
  end


  function cc.incdir()
    local incdir = env('LUA_INCDIR',nil)
    return incdir and '-I'..incdir or ''
  end


  function cc.srcout(item)
    if item:find('%.%.') then
      error(('invalid filename: %q'):format(item))
    end
    return table.concat {
      ' -c src/',item,
      ' -o src/',(item:gsub('[^.]+$',OBJ_EXTENSION))
    }
  end

  function cc.libout(mod)
    local dest = COUTDIR..'/lib/'..mod.name:gsub('%.','/')
    -- 'wax.x' to 'wax/x'
    exec('mkdir -p %q', dest:gsub('/[^/]*$',''))
    return dest..'.'..LIB_EXTENSION
  end

  function cc.binout(o) return COUTDIR..'/bin/'..o[1] end


  local
  function clib(mod)
    local create_o  = '@cc @debug @tflags @cflags @incdir @srcout'
    local create_so = '@cc @tflags @sharedflag -o @libout @src @lflags'

    exec('mkdir -p %s/lib', COUTDIR)
    -- For each component of the module
    for s, src in ipairs(mod) do
      -- For each source code
        -- compile each .c to .o
        exec((create_o:gsub('@(%w+)', function(p) return cc[p](src) end)))
        -- replace the name from .c to .o
        mod[s] = src:gsub('[^.]$',OBJ_EXTENSION)
    end
    -- Build compiled items into shared object
    exec((create_so:gsub('@(%w+)',function(p) return cc[p](mod) end)))

    return true
  end

  local
  function cbin(config)
    local cmd = '@cc @debug @incdir @flags @src -o @binout'
    if config.cbin and #config.cbin > 0 then
      exec('mkdir -p %s/bin', COUTDIR)
      for _,o in ipairs(config.cbin) do
        exec((cmd:gsub('@(%w+)',function(p) return cc[p](o) end)))
      end
    end
  end

  help.build = "Compile C code"
  function make.build ()
    local mods = config.modules
    local single = SINGLE_PACKAGE
    if single then
      if mods[single] and mods[single].type == 'lua' then
        local pkgcfg = mods[single]
        for _, mod in pairs(pkgcfg) do
          return clib(mod)
        end
      end
    else
      for pkg, pkgcfg in pairs(mods) do
        for _, mod in pairs(pkgcfg) do
          if mod.type == 'c' then clib(mod) end
        end
      end
    end
    cbin(config)
  end
end


-----------------------------------------------------------
-- EXECUTION ----------------------------------------------
-----------------------------------------------------------

if not make[arg[1]] then
  print('You need to use this script with one of the follow:')
  for cmd,_ in pairs(make) do print(cmd, help[cmd]) end
else
  make[arg[1]]()
end
