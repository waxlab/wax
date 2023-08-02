local argspec = {
{ 'luaver',  'l', '+', desc = 'Use specific Lua version on tests'},
{ 'debug',   nil, '-', desc = 'Enable more verbosity on tests',
                       default=false },
{ 'incdir',  'I', '+', desc = 'Add directory to compiler include path' },
{ 'libdir',  'L', '+', desc = 'Add directory to the library link path' },
{ 'help',    nil, '-', desc = 'Show this help' },
{ 'verbose', 'V', '-', desc = 'More verbosity' },
}

local waxp = require 'waxp'
local wax = require 'wax'
local verbose



local
function parse_target(str)
  local part, module = str:match '^(%a[%w%-]+)%.(.*)'
  if not part then part = str end

  local proj = part:match '^(%a%w+)' or part
  module = module and proj..'.'..module or proj
  return proj, module, part
end


local testpath = waxp.workdir..'/test/?.lua;'
              .. waxp.workdir..'/test/?/init.lua'


local
function runtest(luaver, mod)
  local lua = waxp.luabin(luaver)
  local file = assert(wax.searchpath(mod, testpath))
  local verb = verbose and 'VERBOSE=1' or ''
  local testwrap = ('loadfile[[%ssrc/waxp/testwrap.lua]]()(%q)')
        :format (waxp.selfdir, mod)

  local cmd = ('%s %q -e %q %q'):format(verb, lua, testwrap, file)
  if verbose then
    verbose(nil, cmd)
    verbose('rule', 'testing:')
  end
  if not os.execute(cmd) then
    os.exit(1)
  end
end

-- ppart is to be used when building partial packages.

local
function main()
  local args, help, hint = wax.args(argspec, arg, 2)
  if not args then
    print(hint)
    help()
    os.exit(1)
  end
  verbose = args.verbose and require 'waxp.verbose' or nil
  local project, target = parse_target(args[1])
  local cfg, err = require 'waxp.etc'.project(project)
  if not cfg then
    io.stderr:write('Config error: '..err..'\n')
    os.exit(1)
  end
  local luatarget = args.luaver or cfg.luaver
  if target == project then
    target = cfg.module
  else
    if not cfg.module[target] then
      error(('Module %q not exists for project %q'):format(target, project))
    end
    target = { [1] = target, [target] = cfg.module[target] }
  end

  for _, luaver in ipairs(luatarget) do
    for _, mod in ipairs(target) do
      print(luaver, mod)
      local src = target[mod].src
      waxp.build.compile(mod, target[mod], luaver, args, cfg)
    end
    for _, mod in ipairs(target) do
      runtest(luaver, mod, args.debug)
    end
  end
end

return {
  main = main
}

