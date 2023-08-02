local build = require 'waxp.build'
local sh = require 'waxp.sh'

return function(mod, modconf, luaver)
  local outfile = build.luafilename(luaver, mod)
  sh.copy(modconf.src[1], outfile)
end
