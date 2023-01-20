rockspec = 'wax-latest-1.rockspec'


bin = { }

-- clib paths have are relative to `./src/`
-- ./src/ext - External dependencies (from other projects)
-- ./src/lib - The C code containing the Lua C Api logic
-- ./src/macros
clib = {
	{
		mod = "wax.csv",
		src = { "csv.c"  }
	},
	{
		mod = "wax.fs",
		src = { "fs.c" }
	},
	{
		mod = "wax.json",
		src = { "ext/json/cJSON.c", "json.c" }
	},
	{
		mod = "wax.os",
		src = { "os.c" }
	},
	{
		mod = "wax.sql",
		src = {"sql.c"},
		lflags = "-lsqlite3"
	},
	{
		mod = "wax.user",
		src = { "user.c" }
	},
}
cbin = {
	-- {'target', 'code.c' }
}


--[[
clib = {
	["wax.csv"] = {
		sources = { "csv.c" }
	},
	["wax.fs"] = {
		sources = { "fs.c" }
	},
	["wax.json"] = {
		sources = { "ext/json/cJSON.c", "json.c" }
	},
	["wax.os"] = {
		sources = { "os.c" }
	},
	["wax.sql"] = {
		sources = { "sqlite3.c" },
		flags = { "-lsqlite3" }
	},
	["wax.user"] = {
		sources = { "user.c" }
	},
}
]]
