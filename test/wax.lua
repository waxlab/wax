--| # wax
--| Core functionalities to Wax Lua library

--| Basic require:
--{
local wax = require "wax"
--}


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
