--| # wax.table
--| Extends Lua standard library table module.

--| Basic usage:
--{
local tbl = require 'wax.table'
--}

--$ table.tostring(t: table) : string
--| Serialize a table to a string, stripping functions and userdata.
do
--| Ex: `{a="A","word"}` becomes `"{\"word\",a=\"A\"}"`
--{
local t = {
	a="A", b="B", "fst", [true]=10, ["a b"]=1, c={10,20}, {30,40},
	[function() end] = function() end,
	[function() end] = true,
	[{2,4,6}] = true,
	d = function() end
}
local str = tbl.tostring(t)
local load = require 'wax.compat'.load
local res = load('return '..str)()
assert(res)
assert(res[1] == 'fst')
assert(res[2][1] == 30 and res[2][2] == 40)
assert(res.a == 'A' and res.b == 'B')
assert(res.c[1] == 10 and res.c[2] == 20)
assert(res[true] == 10 and res['a b'] == 1)

-- As functions are system dependent, they are not converted to functions
-- also tables on keys are not supported yet.
for k,v in pairs(res) do
	assert(type(k) ~= 'table')
	assert(type(k) ~= 'function')
	assert(type(v) ~= 'function')
end
--}
end

--$ table.tochunk(t: table) : string
--| Convert a table to a string as if were a chunk of a Lua code.
do
--| The first level of the table become a declaration without the `local`
--| keyword, i.e., only the keys with letters, numbers and underline.
--| Ex: `{ "hi", ["hello world"]="value", hello="ok" }` becomes
--| `"hello = \"ok\"`
--{
local t = {
	a="A", b="B", "fst", [true]=10, ["a b"]=1,
	[function() end] = function() end,
	[function() end] = true,
	[{2,4,6}] = true,
	c = function() end
}
local str = tbl.tochunk(t)
local load = require 'wax.compat'.load
local res = {}
load(str,res)()
assert(res.a == "A" and res.b == "B")
assert(res[1] == nil)
assert(res[true] == nil and res["a b"] == nil)
--}
end
