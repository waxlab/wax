local
  wax_argerror,
	wax_from,
  wax_ismainmodule,
	wax_locals, _locals_mt,
	wax_script

local unpack = table.unpack or unpack

local fs_realpath = require 'wax.fs'.realpath


function
  wax_script()
	  local s = debug.getinfo(2,'S')
	  if s then return fs_realpath(s.short_src) end
	  return nil
end


function
  wax_ismainmodule()
    return arg[0] == debug.getinfo(2).short_src
end


function
  wax_locals()
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


function
  wax_argerror(n,exp)
    local fname = debug.getinfo(2,'n').name
    error(("bad argument #%d to '%s' (%s expected)"):format(n,fname or '?',exp),3)
end


function
  wax_from(src, ...)
    local srctype = type(src)
    if srctype == 'string' then
      src     = require(src)
      srctype = type(src)
    end
    if srctype == 'table' then
      local t = {...}
      for n,v in pairs(t) do t[n] = src[v] end
      return (table.unpack or unpack)(t)
    end
    wax_argerror(1,"table or module name")
end


return {
	argerror     = wax_argerror,
	from         = wax_from,
	ismainmodule = wax_ismainmodule,
	locals       = wax_locals,
	script       = wax_script,
}
