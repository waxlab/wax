--[[
Compiling from C
----------------

A C source file compilation can be tuned via the target package configuration,
in the properties of each module or via arguments when calling the builder,
i.e. through ``waxp build`` and by extension, its wrapper ``waxp test``, and
some also via environment variables.

^^The C source file^^ is defined only on package configuration module entries by
the entry ``src``. There, it can be informed via a string containing the path
for the C source file or a list of them.

^^Include paths^^, where compiler should find the headers, can be informed via
the builder option -I or --include or via the environment ``$CPATH``. The local
``./src`` and ``/usr/include`` and ``/usr/local/include`` are used by default,
and also Lua headers will be automatically resolved looking at these places.

^^External libraries^^ can be linked using the module config with the entry
``lib`` that can be a string or a list.

^^External libraries path`` can be included into the searcher adding the
``libpath`` entry on module config. This can be a string or a list. A command
line ``--libpath`` can also be informed.
--]]


local waxp = require 'waxp'
local build = waxp.build
local verbose
local pfxtable = {''} -- Used to concatenate options
local table_insert, table_remove, concat,       exec,       getenv
    = table.insert, table.remove, table.concat, os.execute, os.getenv


local
function join(...)
  local res,r = {},1
  for _,a in ipairs{...} do for _,b in ipairs(a) do res[r],r = b,r+1 end end
  return res
end


local
function splitpath (path)
  local list, l = {}, 1
  if path then for v in path:gmatch '[^:]+' do list[l], l = v, l+1 end end
  return list
end



local run
do
  local def = {
    cc = 'gcc',
    std = 'gnu11',
    warn = '-Wall -Wextra -Wpedantic',
  }
  function run(opt)
    local repl = function(m) return opt[m] or def[m] or '' end
    local cmd = opt[1]:gsub('@(%w+)', repl)
    verbose(nil, cmd)
    if not exec(cmd) then os.exit(1) end
  end
end


local
function match_lua_header(path, num)
  local f, h, n, msg
  h = path..'/lua.h'
  f, msg = io.open(h, 'r')
  if not f then return false, msg end
  n = f:read('*a'):match 'LUA_VERSION_NUM%s*(%d+)'
  f:close()
  if n and tonumber(n) == num then return true, path end
  return false, ('%q Lua number %d mismatches expected %d'):format(h, n, num)
end


local function find_luainc(luaver, dirs)
  local ver, shortver, num = waxp.luaver(luaver)
  local places = {}
  for _, d in ipairs(dirs) do
    table_insert(places, d..'/lua' ..ver)      -- Ex: /usr/include/lua5.4
    table_insert(places, d..'/lua/'..ver)      -- Ex: /usr/include/lua/5.4
    table_insert(places, d..'/lua-'..ver)      -- Ex: /usr/include/lua-5.4
    table_insert(places, d..'/lua' ..shortver) -- Ex: /usr/include/lua54
  end

  local tested, t = {}, 1
  for _,dir in ipairs(places) do
    local ok, res = match_lua_header(dir, num)
    if ok then return res end
    tested[t], t = res, t+1
  end

  error(
    ("Couldn't find Lua include files for version %s at\n\t%s"):format(
      tostring(ver),
      concat(tested, '\n\t')
    )
  )
end


local includes
do
  local default, inc = {'./src','/usr/local/include','/usr/include'}
  function includes (args, luaver)
    inc = inc or join( splitpath(getenv 'CPATH'), args.incdir or {}, default)

    if inc[luaver] then return inc[luaver] end
    inc[luaver] = concat( join({'', find_luainc(luaver, inc)}, inc),' -I')
    return inc[luaver]
  end
end


local
function optfrom(copt, conf, arg, env)
  if not conf and not arg and not env then return nil end
  conf = type(conf) == 'table' and conf or {conf}
  arg  = type(arg)  == 'table' and arg  or {arg}
  local ev = env and getenv(env) or nil
  if ev and env == 'LIBRARY_PATH' then ev = splitpath(ev) end
  copt = ' '..copt..' '
  return concat( join( pfxtable, arg, conf, ev ), copt )
end


return
function(mod, modconf, luaver, args, _)
  local o, ofiles, outfile = 1, {}
  verbose = args.verbose and require 'waxp.verbose' or function() end
  verbose('rule', 'compiling:')
  for _, src in ipairs(modconf.src) do
    outfile = build.objfilename(luaver, src)

    run {
      '@cc -g -std=@std @warn -O2 -fPIC @includes -c @c -o @o',
      c = src,
      o = outfile,
      includes = includes(args, luaver),
    }
    ofiles[o], o = outfile, o+1
  end

  run {
    '@cc -shared -o @modfile @ofiles @libpath @lib',
    ofiles  = concat(ofiles,' '),
    modfile = build.libfilename(luaver, mod, 'so'),
    lib     = optfrom('-l', modconf.lib ),
    libpath = optfrom('-L', modconf.libdir, args.libdir, 'LIBRARY_PATH'),
  }
end
