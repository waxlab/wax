local wax = {}

local
	locals, _locals_mt,
	script,
	_

-- TODO: To be moved to wax.test.almostEqual
do
end


function script()
	local realpath = require 'wax.fs'.realpath
	local s = debug.getinfo(2,'S')
	if s then return realpath(s.short_src) end
	return nil
end


function locals()
	local _ENV    = _ENV or _G
	local _ENV_MT = getmetatable(_ENV)

	if not _locals_mt then
		_locals_mt = {
			__newindex = function(_, name)
				local msg = 'variable %q declared without local keyword at %s:%d'
				local info = debug.getinfo(2)
				error( msg:format(name, info.source, info.currentline), 2)
			end
		}
	end

	if _ENV_MT == _locals_mt then return true end

	if not _ENV_MT then
		setmetatable(_ENV,_locals_mt)
		return true
	end
	
	return nil, 'Other metatable is already set for _ENV or _G'
end

return {
	locals = locals,
	script = script,
}
