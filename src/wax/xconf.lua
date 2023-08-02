local xconf = {}
local oas = require 'wax.ordassoc'
local wax  = require 'wax'

-- if cond true returns cond and remaining parameters or throws error
local
function assertl(lvl, cond, msg, ...)
  if cond then return cond, msg, ... end
  lvl = lvl and lvl > 0 and lvl+1 or lvl
  error(msg:format(...), lvl)
end


local
function buildenv(spec)
  local info, conf, parser = debug.getinfo, {}, {}
  for dtv,fn in pairs(spec) do
    assertl(2, type(fn) == 'function', '%q is not a function',dtv)
    local np = info(fn).nparams
    if np == 1 then
      parser[dtv] =
        function(v1)
          assertl(2, not conf.___, 'unfinished directive')
          assertl(2, not conf[dtv], 'duplicated directive %q', dtv)
          conf[dtv] = fn(v1)
        end
    elseif np == 2 then
      local data = oas.new()
      conf[dtv]=data:unwrap()
      parser[dtv] =
        function(a)
          conf.___ = assertl(2, not conf.___, 'unfinished directive')
          return function(b)
            assertl(2, data:insert( assertl(2, fn(a, b)) ) )
            conf.___ = nil
          end
        end
    end
  end
  return conf, parser
end


local
function load(where, what, spec)
  local res, env, fn, err
  res, env = buildenv(spec)
  fn, err =  wax[where == 'file' and 'loadfile' or 'load'](what, env)
  if not fn then return nil, err end
  fn, err = pcall(fn)
  if not fn then return nil, err end
  if res.___ then
    return nil, (
      where == 'file'
        and 'unfinished directive at end of '..what
        or  'unfinished directive at end of config string'
    )
  end
  return res
end


function xconf.loadfile(file, spec)
  return load('file', file, spec)
end


function xconf.load(str, spec)
  return load('str', str, spec)
end

return xconf
