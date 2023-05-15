-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local
  _setfenv,
  _load,
  _loadfile

local luaver = _VERSION:gsub('.* ([%d.]*)$','%1')

if luaver == '5.1' then

  _setfenv = setfenv

  function _load(chunk, envt)
    local fn, err = loadstring(chunk, nil)
    if not fn then return fn, err end
    if envt then setfenv(fn, envt) end
    return fn
  end

  function _loadfile(filename, envt)
    local fn, err = loadfile(filename)
    if err then return fn, err end
    if envt then return setfenv(fn, envt) end
    return fn
  end

else

  function _setfenv(fn, envt)
    debug.upvaluejoin(fn, 1, function() return envt end, 1)
    return fn
  end

  function _load(chunk, envt)
    return load(chunk, nil, 't', envt)
  end

  function _loadfile(f, e)
    return loadfile(f, 't', e)
  end

end

return {
  setfenv  = _setfenv,
  load     = _load,
  loadfile = _loadfile
}
