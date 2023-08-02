local sh = require 'waxp.sh'
local conf = require 'waxp.config'

local sparse = {}

function sparse.run()
  print [[

    Sparse, a semantic parser and static analyzer for C.
    For info see: https://sparse.docs.kernel.org

  ]]

  local sparse_cfg = {
    std = 'gnu89',
  }

  if arg[2] == 'help' then
    print [[
    help       print this help
    --file=X   sparse only X (default all C from config)
    --std=X    use C standard X (default gnu89)
    ]]
  end

  for i=2, 4, 1 do
    if arg[i] then
      local c,v = arg[i]:match('%-%-(%w+)=(.+)')
      if c and v then conf[c]=v end
    end
  end

  sparse = ([[
    sparse -Wsparse-error
      -std=%q
      -Wno-declaration-after-statement
      -Wsparse-all
      -I/usr/include/lua%s
      -I./src
      %q 2>&1
      | grep -v "unknown attribute\|note: in included file"
  ]]):gsub('\n',' ')

  for _,lua in pairs(conf.lua) do
    sh.printhead (("Sparse for Lua %s"):format(lua))
    if sparse_cfg.file then
      sh.printbody('parsing "'..file..'"')
    else
      for pkg,mods in pairs(conf.modules) do
        for mod, modcfg in pairs(mods) do
          if modcfg.type == 'c' then
            for _,file in ipairs(modcfg) do
              sh.printbody('parsing "'..file..'"')
              sh.exec(sparse,sparse_cfg.std, lua,file)
            end
          end
        end
      end
    end
    sh.printfoot ("")
  end

  print("\nSparsed OK! :)\n")
end


local waxarg = require 'wax.arg'

local cmd_options = {
  {
    long = 'test',
    short = 't',
    desc = 'Test example',
    value = false,
  }
}


function sparse.main(config, arg, argidx)
  --local opt =  cliopt.parse(arg, cmd_options, argidx)
  --require 'wax'.show(opt)
  require 'test.waxp.cliopt'
end



return sparse
