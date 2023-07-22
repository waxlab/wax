local confex = {}
local orec = require 'wax.ds.orecord'

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
      local data = orec.new()
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


function confex.loadfile(file, spec)
  local res, env
  res, env = buildenv(spec)
  assertl(0, require 'wax'.loadfile(file, env))()
  if res.___ then
    error('unfinished directive at end of '..file, 0)
  end
  return res
end


function confex.load(str, spec)
  local res, env
  res, env = buildenv(spec)
  assertl(0, require 'wax'.load(str, env))()
  if res.___ then
    error('unfinished directive at end of config string', 0)
  end
end

return confex
