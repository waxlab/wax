local function err_delim(str,delim,pos)
  local l, p = 0, 0
  repeat l = l+1 p = str:find('([\r\n])',p+1) until not p or p >= pos
  error(('Template error on line %d: ´%s´ expected.'):format(l, delim))
end


local function err_lua(str)
  return str:gsub('^.*:(%d+:)','Lua template error on line %1.')
end


local function to_str_chunk(str)
  return ("__T[__P]=%q;__P=__P+1;"):format(str)
end


local to_lua_chunk = {
  ['%'] = function (str) return str end,
  ['='] = function (str) return ("__T[__P]=%s;__P=__P+1;"):format(str) end
}


local function find_str_dlim(str,pos,q)
  local p1,p2 = str:find(q,pos,true)
  if not p1 then
    return err_delim(str, q, pos)
  end
  if str:sub(p1-1,p1-1) ~= "\\" then return p1, p2 end
  return find_str_dlim(str, p2+1, q)
end


local function find_lua_dlim(str, pos, lbpos, lb)
  local p1,p2,d,_

  p1,p2,p,d = str:find([=[%s*([\\%%=]*)(["'}])]=],pos)
  if not p1 then
    err_delim(str, lb.."}", lbpos)
  end

  if d == '}' then
    if p == lb then
      if str:sub(p2,p2+1) == "}\n" then p2=p2+1 end
      return p1, p2
    end
  else
    _, p2 = find_str_dlim(str,p2+1,d)
    return find_lua_dlim(str,p2+1,lbpos,lb)
  end

  return find_lua_dlim(str,p2+1,lbpos,lb)
end


local function tolua(t, str, pos)
  local b1,b2,d = str:find('{([%%=])%s*',pos)
  t[#t+1] = to_str_chunk(str:sub(pos, (b1 or 0) -1))
  if not b1 then
    t[#t+1] = "return __T"
    return table.concat(t,' ')
  end
  local p1, p2 = find_lua_dlim(str, b2+1, b2+1, d)
  t[#t+1] = to_lua_chunk[d](str:sub(b2+1,p1-1))
  return tolua(t,str,p2+1)
end

local compile

if _VERSION == "Lua 5.1" then
  compile = function (str, fenv)
    local fn, err = loadstring( tolua({'local __T,__P={},1;'},str,0), nil)
    if err then error(err:gsub('^.*:(%d+:)','Template error on line %1')) end
    return setfenv(fn, fenv)()
  end
else
  compile = function (str, fenv)
    return load(tolua({'local __T,__P={},1;'},str,0), nil, 't', fenv)()
  end
end


function parse(str, data, env)
  env = env or _ENV or _G
  if not env.__index then env.__index = env end
  local fenv = setmetatable({data=data},env)
  local ok, res = pcall(compile, str, fenv)
  if ok then
    return table.concat(res)
  else
    return nil, err_lua(res)
  end
end

------------

local str = [[
<ul>
{% function teste() return 10 end %}
{% for x,v in ipairs(data) do %}
<li>{= v =}</li>
<li>{= teste() =}</li>
{% for x,v in ipairs(data) do %}
laa
{% end %}
{% end %}
</ul>
]]

local data = { "ola", "mundo" }
local a, b = parse(str,data, {error=error, ipairs=ipairs} )
print(a)
