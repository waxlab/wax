-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--| # wax
--| Core functionalities to Wax Lua library

--| Basic require:
--{
local wax = require "wax"
--}


--$ `wax.argerror(argnum: integer, expected: string) : void`
--| This function simplify the error throwing with a more luaish message.
--| The `argnum` represents which argument to the function is wrong while
--| `expected` is the message informing what the function expects to this
--| argument.
--|
--| Example:
--| ```
--| local function sum(a,b)
--|   if not type(a) == 'number' then wax.argerror(1, 'number') end
--|   if not type(b) == 'number' then wax.argerror(2, 'number') end
--|   return a+b
--| end
--| ```



--$ wax.from(src: table|string, ...: string) : any...
--| Allows to unpack only certain keys from a table or module.
--|
--| If `src` is a table, it retrieves its keys that matches with `...` arguments.
--| If `src` is a string, so it is required as a module and processed as table.
--| This function returns the values in the same order specified on `...`.
--|
--| Example 1: suppose you only want some functions or members of a module
do
--{
  local isdir, isfile = wax.from('wax.fs','isdir','isfile')
  assert(type(isdir)  == 'function')
  assert(type(isfile) == 'function')
--}
end
--| Example 2: suppose you have some variables that are used repeatedly and
--| by some reason you need to avoid table lookup to access them in a loop:
do
--{
  local sat = { "Moon", "Io", "Titan", nil, "Charon" }
  local earth, b612, pluto = wax.from(sat, 1,4,5)

  assert(earth == 'Moon')
  assert(b612  == nil)
  assert(pluto == 'Charon')
--}
--| Attention! If you are extracting members from a module, and this module
--| has some lazyloading mechanism for its members, the inner module require
--| may throw errors.
  local res, msg
  res, msg = pcall(wax.from)
  assert(res == false)
  assert(msg == "bad argument #1 to '?' (table or module name expected)")

  for _,v in ipairs {10,false,true,io.stderr} do
    local res, msg = pcall(wax.from, v)
    assert(res == false and type(msg) == 'string')
  end

  res, msg = pcall(wax.from, false)
end
--| Most of time you will use variables via table access with no problem. But
--| there are specific cases when `wax.from()` can help a lot. A good example
--| is code inside loops that need to access table members, multiplying the
--| cost of the operation. Keeping a local reference to the function to be
--| accessed directly from loop can provide better performance.



--$ `wax.ismainmodule() : bool`
--| (Experimental)
--| Return `true` if it is called in the same script that was called on
--| the Lua REPL.
--|
--| It is useful if you write a module that can be required on other
--| Lua scripts or can be called directly from the command line.
--|
--| Example:
--|
--| ```
--| local wax = require 'wax'
--| local function sum(a, b) return a+b end
--|
--| if wax.ismainmodule() then
--|   sum(arg[1],arg[2])
--| else
--|   return {
--|     sum = sum
--|   }
--| end
--| ```



--$ `wax.locals() : nil`
--| Once this function is called, it blocks any attempt to create a new
--| variable without the use of local keyword.
--|
--| Further calls to this function have no effect.



--$ wax.lazy(name: string, module : table)
--|
--| Lazy loader for module members. As your module grows,
--| you may have more specific and less used functions, or even
--| exclusive functions (using one doesn't use other). So, have
--| all its logic inside a module may sound unnecessary.
--|
--| Also, some lower level functionality may fit in one function,
--| but can demand a longer logic on the C side. So a C module
--| can produce a single Lua function and act as a module function.
--|
--| Example:
--|
--| In module `x`:
--| ```
--| local module = {}
--| function module.a() return "A" end
--| function module.b() return "B" end
--| return (require "wax").lazy("x",module)
--| ```
--|
--| In module `x.y`
--| ```
--| return function() return "Y" end
--| ```
--|
--| Now you need only to require the module `x`:
--| ```
--| local x = require `x`
--| x.a() -- prints "A"
--| x.b() -- prints "B"
--| x.y() -- prints "Y"
--| ```
--|
--| In the moment you call `x.y()`, the function `y` doesn't
--| exist in the `x` module. So it tries to load from a `x.y`
--| module.



--$ wax.script()
--| Returns the full path for the current script file
--| where it was called.
do
--{
  assert(wax.script():match('test/wax.lua$'))
--}
end



--$ wax.similar( t1: any, t2: any )
--| Checks if t1 and t2 have similar contents.
--| It checks recursively on tables instead of just copare the tables with `==`.
--| For other types the comparison is just like `==`; It is useful specially
--| for assertions.
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



--$ wax.tostring(data: any) : string
--| Serialize a value to a string, stripping functions and userdata.
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
local str = wax.tostring(t)
local res = wax.load('return '..str)()
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

--$ wax.tochunk(data: any) : string
--| Convert data to string as if it were a chunk of a Lua code.
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
  local str = wax.tochunk(t)
  local res = {}
  wax.load(str,res)()
  assert(res.a == "A" and res.b == "B")
  assert(res[1] == nil)
  assert(res[true] == nil and res["a b"] == nil)
--}
end



--$ wax.load(chunk: string, env: table)
--| Load the string chunk `chunk` as a function using `env` table as environment.
--| This is a polyfill function for code that should run between different
--| Lua versions.
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
--| This is a polyfill function for code that should run between different
--| Lua versions.
do
local luafile = require 'wax.fs'.getcwd()..'/etc/example/luafile.lua'
--{
  local env = {}
  local fn, err = wax.loadfile(luafile, env)
  assert(fn() == 'returned value')
  assert(env.somevar == 'some value')
--}
end



--$ wax.setfenv(fn: function, envt: table)
--| Set the `envt` table as environment for the function `fn`.
--| This is a polyfill function for code that should run between different
--| Lua versions.
do
--{
local function fn() return value end
wax.setfenv(fn,{value=10})
assert(fn() == 10)
--}
end
