--| # wax.was
--| Assertion functions for data validation.
--|
--| Basic usage:
--{
	local was = require 'wax.was'
	was.similar('hi','hi')
--}

--$ was.similar( t1: any, t2: any )
--| Checks if t1 and t2 have similar contents.
--| It checks recursively on tables instead of just copare the tables with `==`.
--| For other types the comparison is just like `==`; It is useful specially
--| for assertions.
do
--{

	-- Behaves like `==` for numbers, strings, booleans, userdata and functions.
	assert( was.similar("hi", "hi") )
	assert( not was.similar("Hi", "hi") )
	assert( was.similar(10, 10.0) )
	assert( was.similar(false, false) )
	assert( not was.similar(true, false) )
	assert( not was.similar(false, nil) )

	local ud1, ud2 = io.open('/dev/null'), io.open('/dev/null')
	assert( type(ud1) == type(ud2) and was.similar(ud1, ud2) == (ud1 == ud2) )

	local f1, f2 = function() end, function() end
	assert( f1 ~= f2 and not was.similar(f1,f2))

	-- Tables and functions are not compared by their pointer like in `==` but by
	-- their internal value.
	local t1, t2 = {}, {}
	assert( (t1 == t2) == false )
	assert( was.similar(t1,t2) == true)

	-- To be similar, both tables need to share the same metatable
	setmetatable(t1,{})
	setmetatable(t2,{})
	assert( was.similar(t1, t2) == false)

	setmetatable(t2,getmetatable(t1))
	assert( was.similar(t1, t2) == true)

	-- The test of similarity extends deeply (be careful with circular references)
	t1 = { a = {1,2,3}, '', 10.0, {true} }
	t2 = { a = {1,2,3}, '', 10, {true} }
	assert( was.similar(t1, t2) )

	t2 = { a = {1,2,3}, '', 10, {true}, c={} }
	assert( not was.similar(t1, t2) )
--}
end
