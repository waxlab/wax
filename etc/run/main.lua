#!/usr/bin/env lua
--| It is an automation system for development and code publishing
--|
--| * clean      Remove compile and test stage artifacts
--| * dockbuild  Build Docker instance for tests
--| * docklist   List available Docker confs
--| * dockrun    Run command on Docker test instance
--| * docktest   Run Lua deva files through the Docker test instance
--| * howl       Update documentation using howl
--| * help       Retrieve the list of documented items
--| * install    Install the rockspec for all Lua versions
--| * remove     Uninstall the rockspec for all Lua versions
--| * sparse     Run semantic parser for C
--| * test       Compile, and run Lua deva files

local command = {}
local sh = require 'etc.run.sh'
local config = require 'etc.run.config'
local luaVersions = {"5.1","5.2","5.3","5.4"}
local mandir  = "./man"
local testdir = "./test"

local luabin = {
	["5.1"] = sh.whereis("lua%s","5.1","51"),
	["5.2"] = sh.whereis("lua%s","5.2","52"),
	["5.3"] = sh.whereis("lua%s","5.3","53"),
	["5.4"] = sh.whereis("lua%s","5.4","54"),
}


function test_compile(luaver, module)
	print(("\n╒═══╡ Compiling for Lua %s"):format(luaver))
	if (module) then
		sh.exec("SINGLE_MODULE=%q LUA_VERSION=%q WAXTFLAG=1 luarocks --tree ./tree --lua-version %s make %s",module, luaver, luaver, config.rockspec)
	else
		sh.exec("LUA_VERSION=%q WAXTFLAG=1 luarocks --tree ./tree --lua-version %s make %s",luaver,luaver,config.rockspec)
	end
end

function test_lua(luaver,module)
	local lbin  = luabin[luaver]
	local lpath = ("./tree/share/lua/%s/?.lua;./tree/share/lua/%s/?/init.lua"):format(luaver,luaver)
	local cpath = ("./tree/lib/lua/%s/?.so" ):format(luaver)
	local cmd = ('find %q -name "*.lua" 2>/dev/null'):format(testdir)
	if module then
		cmd = ("%s| grep '^%s/%s$'"):format(cmd, testdir, module:gsub('%.', '/')..'.lua')
	end

	local p = io.popen(cmd:format(testdir, module),"r")
	if p == nil then return end

	print(("╞═══╡ Testing with Lua %s\n│"):format(luaver))
	testnum = 0
	local file = p:read()
	while file do
		testnum = testnum + 1
		io.stdout:write(("├╶╶╶ %s\n"):format(
			file:gsub('./test/','')
					:gsub('%.lua$', '')
					:gsub('/','.')))
		sh.exec(
			[[ TZ=UTC+0 %s -e 'package.path=%q package.cpath=%q' %q ]],
			lbin, lpath, cpath, file
		)
		file = p:read()
	end
	io.stdout:write(
		("│\n╰╶╶╶ %d tests\n\n\n"):format(testnum)
	)
end

function docker_names()
	local files = sh.rexec("ls etc/docker/*.dockerfile")
	local names = {}
	for i,dfile in ipairs(files) do
		names[dfile:gsub("^.*/",""):gsub(".dockerfile$","")] = 1
	end
	return names
end

function docker_image(name)
	name = name or "luawax_debian"
	if sh.OS ~= "Linux" then
		print("This command requires a Linux machine host")
		os.exit(1)
	end
	if not docker_names()[name] then
		command.docklist()
		os.exit(1)
	end

	local name = sh.rexec("docker images | grep %q | awk '{print $1}'",name)[1]
	if not name then
		print(("Try build first with:\n\n\t./run dockbuild %s\n"):format(arg[2]))
		os.exit(1)
	end
end


--
-- Public actions
-- Below functions are used as actions called directly from Ex:
-- ./run docklist

function command.clean()
	print("Cleaning project")
	sh.exec("rm -rf ./tree ./wax ./out ./lua ./luarocks ./lua_modules ./.luarocks")
	sh.exec("rm -rf ./lua ./luarocks ./lua_modules ./.luarocks")
	sh.exec("find ./src -name '*.o' -delete")
	sh.exec("find ./src -name '*.out' -delete")
end


function command.help()
	cmd = ([[
	{ cat $(find %s -name '*.lua') | grep '^\s*\--\$' | cut -d\$ -f2- |cut -d' ' -f2-;
		cat $(find %s -name '*.md') | grep '######'|cut -d' ' -f2- | tr -d '`';
	} 2> /dev/null | fzf
	]]):format(testdir,mandir)
	os.execute(cmd)
end


function command.howl()
	print 'Generating wiki...'
	os.execute 'howl --from ./test --from ./doc --fmt wiki ../wax.wiki'
	print 'Generating vim help...'
	os.execute 'howl --from ./test --from ./doc --fmt vim ~/.config/nvim/doc/wax'
	print 'Updating vim help tags...'
	os.execute 'nvim --cmd ":helptags ~/.config/nvim/doc\n" --cmd ":q"'
	print 'Done.'
end


function command.test()
	local module = arg[2]
	for i,luaver in ipairs(luaVersions) do
		test_compile(luaver, module)
		test_lua(luaver, module)
	end
end


function command.sparse()
	print [[

		Sparse, a semantic parser and static analyzer for C.
		For info see: https://sparse.docs.kernel.org

	]]

	local conf = {
		std = 'gnu89',
		file = 'src/*.c'
	}
	if arg[2] == 'help' then
		print [[
		help       print this help
		--file=X   sparse only X (default *)
		--std=X    use C standard X (default gnu89)
		]]
	end
	for i=2, 4, 1 do
		if arg[i] then
			local c,v = arg[i]:match('%-%-(%w+)=(.+)')
			if c and v then conf[c]=v end
		end
	end

	local cmd = table.concat {
		(' for i in %s; do '):format( conf.file ),
			[[ echo sparsing "$i" ; ]],
			[[ sparse -Wsparse-error ]],
				('-std=%s'):format( conf.std ),
				[[ -Wno-declaration-after-statement ]],
				[[ -Wsparse-all ]],
				[[ -I/usr/include/lua%s ]],
				[[ -I./src ]],
				[[ -I./src/ext ]],
				[[ -I./src/lib ]],
				[[ "$i" 2>&1 | ]],
					[[ grep -v "unknown attribute\|note: in included file" | ]],
					[[ tee /dev/stderr; ]],
		[[ done ]]
	}
	print("\nRunning sparse")
	for _,luaver in ipairs(luaVersions) do
		print (("\n╒═══╡ Lua %s"):format(luaver))
		sh.exec(cmd:format(luaver))
		print ("╰╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶╶")
	end
	print("\nSparsed OK! :)\n")
end


function command.docklist()
	print("\nAvailable docker confs:\n")
	for name,_ in pairs(docker_names()) do print(name) end
end


function command.dockbuild()
	local img = docker_image(arg[2])
	if img then
		sh.rexec([[docker rmi "%s:latest"]],img)
		sh.exec([[docker build -t "%s:latest" -f "etc/docker/%s.dockerfile" .]], imgname, imgname)
	else
		command.docklist()
	end
end


docker_run_cmd = [[docker run -ti --rm --mount=type=bind,source=%q,target=/devel %q %s]]
function command.dockrun()
	local img = docker_image(arg[2])

	local runcmd = docker_run_cmd:format(sh.PWD, img, "bash")
	os.execute(runcmd)
end


function command.docktest()
	local strgetimg = "docker images | grep %q | awk '{print $1}'"
	local strcmd    = [[bash -c "cd /devel && TERM=%q ./run test || exit 1; ./run clean"]]
	local strnotimg = "Try build first with:\n\n\t./run dockbuild %s\n"

	local imgname = arg[2] or "luawax_debian"

	if imgname and docker_names()[imgname] then
		imgname = sh.rexec(strgetimg, imgname)[1]
		if not imgname then
			print(strnotimg:format(arg[2]))
			os.exit(1)
		end
		local cmd = strcmd:format(sh.TERM) -- run inside docker
		sh.exec(docker_run_cmd:format(sh.PWD, imgname, cmd))
	end
end

function command.install()
	local cmd = 'luarocks --lua-version %q make %q'
	for k,_ in pairs(luabin) do
		os.execute(cmd:format(k, config.rockspec))
	end
end

function command.remove(rockspec)
	local cmd = 'luarocks --lua-version %q remove %q'
	for k,_ in pairs(luabin) do
		os.execute(cmd:format(k, rockspec or config.rockspec))
	end
end

if command[arg[1]] then
	command[arg[1]]( (table.unpack or unpack)(arg,2) )
else
	local f = io.open(arg[0])
	repeat
		line = f:read()
		if line and line:find('^%-%-[|{}]%s?') == 1 then
			print(line:sub(5))
		end
	until not line
	f:close()
end
