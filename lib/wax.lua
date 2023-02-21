local wax = {}

local
	wax_locals, _locals_mt,
	wax_script,
	wax_from,
	_

local fs_realpath = require 'wax.fs'.realpath



function wax_script()
	local s = debug.getinfo(2,'S')
	if s then return fs_realpath(s.short_src) end
	return nil
end


function wax_locals()
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


local function wax_from(src, ...)
	if type(src) ~= 'table' then src = require(src) end
	local t = {...}
	for i,v in ipairs(t) do t[i] = src[v] end
	return (table.unpack or unpack)(t)
end


return {
	locals = wax_locals,
	script = wax_script,
	from   = wax_from
}
