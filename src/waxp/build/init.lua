local sh = require 'waxp.sh'

local outprefix = '.local/lua%s'
local objpath = '.local/cache/lua%s/%s.o'
local modpath = outprefix..'/%s.%s'
local installfrom = '.local/lua%s/%s'
local installto   = '%s/lua%s/%s'

local build = {

  libfilename =
    function(lv, mod)
      local path = modpath:format(lv, mod:gsub('%.', '/'),'so')
      sh.mkdir(path, true)
      return path
    end,

  luafilename =
    function(lv, mod)
      local path = modpath:format(lv, mod:gsub('%.', '/'), 'lua')
      sh.mkdir(path, true)
      return path
    end,

  objfilename =
    function(lv, src)
      local path = objpath:format(lv, src:gsub('%.c$', ''))
      sh.mkdir(path, true)
      return path
    end,

  outprefix = outprefix,
}


function build.compile(mod, modconf, luaver, args, cfg)
  local ext = modconf.src[1]:match('%.([%w]+)$')
  if not build[ext] then
    error(('files with extension %q are not supported'):format(ext))
  end
  build[ext](mod, modconf, luaver, args, cfg)
end

function build.install(pkg, luaver, pfx)
  local from = installfrom:format(luaver, pkg)
  local to   = installto:format(pfx, luaver, pkg)

  if sh.isdir(to) then
    io.stderr:write(('The path %q already exists\n'):format(to))
    os.exit(1)
  end

  if not sh.isdir(from) then
    local proc = io.popen(('%q test --luaver %q %q; echo $?'):format(arg[0],luaver,pkg))
    local curr, line = nil, proc:read()
    while line do
      sh.printbody(line)
      curr, line = line, proc:read()
    end
    if curr ~= '0' then
      sh.exec('rm -rf %q', from)
      os.exit(1)
    end
  end

  sh.mkdir(to, true)
  sh.exec('mv %q %q', from ,to)
  io.stdout:write( ('\n\n%q was installed into %q\n\n'):format(pkg, to) )

  io.stdout:write(([[
  Add the following lines on your system shell to make the module found:

  export LUA_PATH_{{cst}}="{{pfx}}/lua{{ver}}/?.lua;{{pfx}}/lua{{ver}}/?/init.lua;;"
  export LUA_CPATH_{{cst}}="{{pfx}}/lua{{ver}}/?.so;{{pfx}}/lua{{ver}}/?/init.so;;"
  ]]):gsub('{{(%w+)}}', {
    ver = luaver,
    cst = luaver:gsub('%.','_'),
    pfx = pfx
  }))

end

return require 'wax.lazy'('waxp.build', build)
