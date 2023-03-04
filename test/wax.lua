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


--$ wax.script()
--| Returns the full path for the current script file
--| where it was called.
do
--{
	assert(wax.script():match('test/wax.lua$'))
--}
end


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
	local isdir, darkside, isfile = wax.from('wax.fs','isdir','darkside','isfile')
	assert(type(isdir)  == 'function')
	assert(type(isfile) == 'function')
	assert(darkside == nil) -- doesn't exist
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
