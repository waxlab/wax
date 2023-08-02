local sh = require 'waxp.sh'


local objpath = '.local/cache/lua%s/%s.o'
local modpath = '.local/land%s/%s.%s'

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

}






function build.compile(mod, modconf, luaver, args, cfg)
  local ext = modconf.src[1]:match('%.([%w]+)$')
  if not build[ext] then
    error(('files with extension %q are not supported'):format(ext))
  end
  build[ext](mod, modconf, luaver, args, cfg)
end

return require 'wax.lazy'('waxp.build', build)
