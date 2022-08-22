--
-- LUA LEVELING
-- Make a common place to work between different Lua versions
--
local _load   -- load string as Lua function
    , _setenv -- defines a function environment

if _VERSION == "Lua 5.1" then
  _setenv = setfenv
  _load   = function (str) return loadstring(str, nil) end
else
  local uvj = debug.upvaluejoin
  _setenv = function (f, e) uvj(f, 1, function() return e end, 1) return f end
  _load   = function (str) return load(str, nil, 't') end
end
-- End Lua leveling



--
-- DEFAULT TEMPLATE ENVIRONMENT
-- Create an environment with a subset of the standard Lua library
-- avoiding functions to manipulate files, call processes or
-- use the debug library and metatables.
--

local ENV

do
  ENV = {
    math={}, os={}, string={}, table={},
    ipairs   = ipairs,
    pairs    = pairs,
    tonumber = tonumber,
    tostring = tostring,
    error    = error,
    type     = type,
    next     = next,
    __S      = tostring,
    _G       = nil,
    _ENV     = nil
  }

  local math, string, table = math, string, table
  for k,v in pairs(math)   do ENV.math[k] = v end
  for k,v in pairs(string) do ENV.string[k] = v end
  for k,v in pairs(table)  do ENV.table[k] = v end

  for _,v in ipairs{'clock','date','difftime','time'} do ENV.os[v] = os[v] end
  ENV.__index = ENV
end


--
-- ERROR FUNCTIONS
-- These filter the error messages to find where the error
-- ocurred in the compiled template
--

local
function err_lua(str)
  return str:gsub('^.*:(%d+:)','Lua template error on line %1')
end


--
-- PRE-PROCESS FUNCTIONS
-- the below section has the functions used by `preproc`
--
local backfilter = {
  ['**'] = function(s) return s:gsub("[%s]+$",'') end,
  ['*'] = function(s) return s:gsub("[%s]+$",' ') end,
  ['++'] = function(s) return s:gsub("[ ]+$",'') end,
  ['+'] = function(s)
    local m = s:gsub('[ ]*$','')
    local l = m:sub(-1)
    if l ~= '' and l ~='\n' then m=m:gsub('$',' ') end
    return m
  end
}

local
function check(T,t,s,l,r, match, fmt, next)
  local fl, fr, bf = s:find(match, l)
  if fl and fl > r then fl = nil end
  if fl and bf and bf ~= ''
    then
      if backfilter[bf]
        then T[t] = fmt:format(tostring(backfilter[bf](s:sub(l, (fl or r+1) - 1))))
        else error(('Invalid backfilter %q near %d'):format(bf, fl))
      end
    else T[t] = fmt:format(tostring(s:sub(l, (fl or r+1) - 1)))
  end
  if fl then return next(T, t+1, s, fr+1, r) end
  return T, t
end

local checkval, checkcmt
do
  function checkval(T,t,s,l,r)
    return check(T,t,s,l,r, '%s*}}', '__R(%s)', checkcmt)
  end

  function checkcmt(T,t,s,l,r)
    return check(T,t,s,l,r, '{{([%*%+]*)%s*', '__R(%q)', checkval)
  end
end

local chunktpl, chunklua
do
  function chunklua(T, t, s, l)
    if l then
      local fl, fr = s:find('%-%-%[%[\n?',l)
      T[t] = s:sub(l, (fl or 0)-1 )
      if fl then return chunktpl(T, t+1, s, fr+1) end
    end
    return T, t
  end

  function chunktpl(T, t, s, l)
    if l then
      local fl, fr = s:find('%]%]\n?', l)
      T,t = checkcmt(T, t, s, l, (fl and fl-1 or s:len()) )
      if fl then return chunklua(T, t+1, s, fr+1) end
    end
    return T, t
  end
end


local
function preproc (s, startwithlua)
-- Naming:
-- T, t = table and table index
-- s = string
-- l, r = left/right position (start/ends at)
-- fl, fr = found left/right pos (found starts/ends at)
--    return tolua({'local __T,__C={},1;'},str,0,1)
  local T={[[
    local __R
    do
      local T,t,tostring={},1,tostring;
      function __R(v,r)
        if not v then return T end
        T[t],t=tostring(v),t+1
      end
    end
  ]]}
  local t=1
  if startwithlua
    then T,t = chunklua( T, t+1, s, 0 )
    else T,t = chunktpl( T, t+1, s, 0 )
  end
  T[t+1]='return __R()'
  return table.concat(T,' ')
end
-- End pre-processor functions


--
-- TEMPLATE CLASS
--

local WaxTemplate = {}
WaxTemplate.__index = WaxTemplate


function WaxTemplate:__call(data)
  local env = { data = data }
  env.__index = env
  setmetatable(env, self.env)
  local ok, res = pcall(_setenv( self.fn, env))
  if ok
    then return table.concat(res)
    else return nil, err_lua(res)
  end
end


function WaxTemplate:assign(name, value)
  local env = self.env
  if type(name) == 'table'
    then for k,v in pairs(name) do env[k] = v end
    else env[name] = value
  end
end


function WaxTemplate.new(fn)
  local env = setmetatable({}, ENV)
  env.__index = env
  return setmetatable({env=env, fn=fn}, WaxTemplate)
end


--
-- PUBLIC
--

local template = { WaxTemplate = WaxTemplate }


function template.format (str, data)
  local fn, err = _load(preproc(str))
  if err
    then return nil, err_lua(err)
    else
      local ok, res = pcall(_setenv(fn, setmetatable({data=data or {}}, ENV)))
      if ok then return table.concat(res) end
      return nil, err_lua(res)
  end
end


function template.load(t)
  local fn, err = _load(preproc(t))

  if err
    then return nil, err_lua(err)
    else return WaxTemplate.new(fn)
  end
end


function template.loadfile(filename, prefilters)
  local f, reason = io.open(filename,'r')
  if not f then error(reason,2) end
  local fn, err = _load(preproc(f:read('*a'),'lua'))
  if err
    then return nil, err_lua(err)
    else return WaxTemplate.new(fn)
  end
end

return template
