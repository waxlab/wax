--| # wax - Wax Lua package core functionalities

--| ## Wax limits global variables.

--| When the wax module is required, the global table `_G` is set to read-only.
--| This means that when trying to set a new global variable by ommiting the
--| `local` keyword an error is thrown.
--| There some huge benefits, as global variables are not garbage collected and
--| you have to access only predefined variables (global or upvalues) and set
--| variables only locally.
--| Global variables can still be set, but only using `rawset` against `_G`.



--| ## Functions

local wax = require "wax"
do
--| @ wax.similar( t1: any, t2: any )
--| Checks if t1 and t2 have similar contents.
--| It checks recursively on tables instead of just copare the tables with `==`.
--| For other types the comparison is just like `==`; It is useful specially
--| for assertions.

  local similar = wax.similar

  -- Behaves like `==` for numbers, strings, booleans, userdata and functions.
  assert( similar("hi", "hi") )
  assert( not similar("Hi", "hi") )
  assert( similar(10, 10.0) )
  assert( similar(false, false) )
  assert( not similar(true, false) )
  assert( not similar(false, nil) )

  local ud1, ud2 = io.open('/dev/null'), io.open('/dev/null')
  assert( type(ud1) == type(ud2) and similar(ud1, ud2) == (ud1 == ud2) )

  local f1, f2 = function() end, function() end
  assert( f1 ~= f2 and not similar(f1,f2))

  -- Tables and functions are not compared by their pointer like in `==` but by
  -- their internal value.
  local t1, t2 = {}, {}
  assert( (t1 == t2) == false )
  assert( similar(t1,t2) == true)

  -- To be similar, both tables need to share the same metatable
  setmetatable(t1,{})
  setmetatable(t2,{})
  assert( similar(t1, t2) == false)

  setmetatable(t2,getmetatable(t1))
  assert( similar(t1, t2) == true)

  -- The test of similarity extends deeply (be careful with circular references)
  t1 = { a = {1,2,3}, '', 10.0, {true} }
  t2 = { a = {1,2,3}, '', 10, {true} }
  assert( similar(t1, t2) )

  t2 = { a = {1,2,3}, '', 10, {true}, c={} }
  assert( not similar(t1, t2) )

end
