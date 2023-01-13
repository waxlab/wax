--| # wax
--| Core functionalities to wax.Wax Lua package core functionalities

--| Basic require:
--{
local wax = require "wax"
--}

--$ wax.similar( t1: any, t2: any ) **
--| Checks if t1 and t2 have similar contents.
--| It checks recursively on tables instead of just copare the tables with `==`.
--| For other types the comparison is just like `==`; It is useful specially
--| for assertions.
--| TODO: This function is to be placed in a test module.
do
--{

	-- Behaves like `==` for numbers, strings, booleans, userdata and functions.
	assert( wax.similar("hi", "hi") )
	assert( not wax.similar("Hi", "hi") )
	assert( wax.similar(10, 10.0) )
	assert( wax.similar(false, false) )
	assert( not wax.similar(true, false) )
	assert( not wax.similar(false, nil) )

	local ud1, ud2 = io.open('/dev/null'), io.open('/dev/null')
	assert( type(ud1) == type(ud2) and wax.similar(ud1, ud2) == (ud1 == ud2) )

	local f1, f2 = function() end, function() end
	assert( f1 ~= f2 and not wax.similar(f1,f2))

	-- Tables and functions are not compared by their pointer like in `==` but by
	-- their internal value.
	local t1, t2 = {}, {}
	assert( (t1 == t2) == false )
	assert( wax.similar(t1,t2) == true)

	-- To be similar, both tables need to share the same metatable
	setmetatable(t1,{})
	setmetatable(t2,{})
	assert( wax.similar(t1, t2) == false)

	setmetatable(t2,getmetatable(t1))
	assert( wax.similar(t1, t2) == true)

	-- The test of similarity extends deeply (be careful with circular references)
	t1 = { a = {1,2,3}, '', 10.0, {true} }
	t2 = { a = {1,2,3}, '', 10, {true} }
	assert( wax.similar(t1, t2) )

	t2 = { a = {1,2,3}, '', 10, {true}, c={} }
	assert( not wax.similar(t1, t2) )
--}
end


--$ wax.load(chunk: string, envt: table)
--| Load the string chunk `chunk` as a function using `envt` table as environment
do
--{
	local env = {}
	local fn, err = wax.load([[myvar = { key = "value" }]], env )
	assert(fn() == nil, err == nil)  -- Function does not return anything
	assert(env.myvar.key == "value") -- But its environment is affected

	local fn, err = wax.load([[ return myvar.key .. myvar.key ]], env )
	assert(fn() == 'valuevalue')
--}
end


--$ wax.loadfile(filename: string, envt: table)
--| Does the same as the `wax.load` but loading from a file instead.
do
local luafile = require 'wax.fs'.getcwd()..'/etc/example/luafile.lua'
--{
	local env = {}
	local fn, err = wax.loadfile(luafile, env)
	assert(fn() == 'returned value')
	assert(env.somevar == 'some value')
--}
end


--$ wax.senfenv(fn: function, envt: table)
--| Set the `envt` table as environment for the function `fn`
do
--{
local function fn() return value end
wax.setfenv(fn,{value=10})
assert(fn() == 10)
--}
end


--$ wax.scriptfile()
--| Returns the full path for the current script file
--| where it was called.
do
--{
	assert(wax.scriptfile():match('test/wax.lua$'))
--}
end
