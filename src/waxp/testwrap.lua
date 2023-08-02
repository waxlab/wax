local luaver = _VERSION:match('[%d%.]+$')
local prefix = '.local/land'..luaver
local pkg = package


local _path = prefix..'/?.lua;'..prefix..'/?/init.lua'
local _cpath = prefix..'/?.so'
local verbose = os.getenv 'VERBOSE' or nil

local
function show_used_path(modname)
  print('looking for '..modname..' at:')
  for v in pkg.path :gmatch('[^;]+') do print('', v) end
  for v in pkg.cpath:gmatch('[^;]+') do print('', v) end
end


return
function(testmod)
  local testpkg = testmod:match('^[^.]+')
  local default_path  = _path ..';'..pkg.path
  local default_cpath = _cpath..';'..pkg.cpath
  pkg.path, pkg.cpath = default_path, default_cpath
  local require = require

  _G.require = function(modname)
    local path, cpath
    -- If the module is part of the tested package, path is restricted
    if modname:match('^[^.]+') == testpkg then
      path, cpath, pkg.path, pkg.cpath = pkg.path, pkg.cpath, _path, _cpath
    end

    if verbose then show_used_path(modname) end
    local a, b = require(modname)

    -- Back to the original paths
    if path then pkg.path, pkg.cpath = path, cpath end
    return a, b
  end

end
