local waxp = require 'waxp'
local wax  = require 'wax'
local verbose
local luatarget

local function main()
  local args, help, hint = wax.args(waxp.buildargs, arg, 2)
  if not args then
    print(hint)
    help()
    os.exit(1)
  end
  verbose = args.verbose and require 'waxp.verbose' or nil

  local pkg, mod, luatgt = waxp.targetmodule(args)

  if pkg ~= mod then
    io.stderr:write('You should install only full packages\n')
    os.exit(1)
  end

  local pfx = os.getenv('INSTALL_PREFIX') or '/usr/local/lib'
  for _,luaver in ipairs(luatgt) do
    waxp.build.install(pkg, luaver, pfx)
  end
end

return {
  main = main
}
