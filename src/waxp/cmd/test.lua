
local waxp = require 'waxp'
local wax = require 'wax'
local verbose
local outprefix = waxp.build.outprefix

local testpath = waxp.workdir..'/test/?.lua;'
              .. waxp.workdir..'/test/?/init.lua'


local function runtest(luaver, mod)
  local lua = assert(waxp.luabin(luaver), 'Lua version '..luaver..' not found!')
  local file = assert(wax.searchpath(mod, testpath))
  local verb = verbose and 'VERBOSE=1' or ''
  local testwrap = ('loadfile[[%ssrc/waxp/testwrap.lua]]()(%q, %q)')
        :format (waxp.selfdir, mod, outprefix)

  local cmd = ('%s %q -e %q %q'):format(verb, lua, testwrap, file)
  if verbose then
    verbose(nil, cmd)
    verbose('rule', 'testing:')
  end
  if not os.execute(cmd) then
    os.exit(1)
  end
end


local function main()
  local args, help, hint = wax.args(waxp.buildargs, arg, 2)
  if not args then
    print(hint)
    help()
    os.exit(1)
  end
  verbose = args.verbose and require 'waxp.verbose' or nil

  local tgt
  local pkg, mod, luatgt, cfg = waxp.targetmodule(args)
  if mod == pkg then
    tgt = cfg.module
  else
    if not cfg.module[mod] then
      error(('Module %q not exists for project %q'):format(mod, pkg))
    end
    tgt = { [1] = mod, [mod] = cfg.module[mod] }
  end

  for _, luaver in ipairs(luatgt) do
    for _, mod in ipairs(tgt) do
      print('Building', luaver, mod)
      waxp.build.compile(mod, tgt[mod], luaver, args, cfg)
    end
    for _, mod in ipairs(tgt) do
      print('Testing', luaver, mod)
      runtest(luaver, mod, args.debug)
    end
  end
end

return {
  main = main
}

