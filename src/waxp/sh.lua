-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

-- Simple functions to handle basic system commands usually used
-- via shell scripts;


local sh = {}

unpack = unpack or table.unpack

local DEBUG = os.getenv('DEBUG')

--[[
$ waxp.sh.mkdir(path:string, pathisfile:boolean)
Create directories in path recursively. If ``pathisfile`` is true, subtracts
the last portion (filename) to get only the dirname of ``path``.
--]]
function sh.mkdir(path, isfile)
  return sh.exec('mkdir -p %q', isfile and path:gsub('/[^/]+$','') or path)
end

--[[
$ waxp.sh.copy(from:string, to:string)
--]]
function sh.copy(from, to)
  return sh.exec('cp -p %q %q', from, to)
end


--[[
$ waxp.sh.printhead(txt:text)
$ waxp.sh.printbody(txt:body)
$ waxp.sh.printfoot(txt:foot)
--]]
do
  local stdout = io.stdout
  local lines, cols
  local p = io.popen('stty size')
  if p then
    lines, cols = p:read():match('(%d+)%s+(%d+)')
    lines = tonumber(lines)
    cols = tonumber(cols)
    p:close()
  end

  function sh.printhead(txt)
    if cols and txt:len() > 0 then
      local l, r =  ' ,=====(  ', '  )'
      txt = txt:sub(0, cols - (l:len() + r:len()) )
      txt = (l..txt..r)
      stdout:write "\n\n"
      stdout:write(txt)
      stdout:write(string.rep("=", cols - txt:len()))
    else
      stdout:write(txt)
    end
    stdout:write "\n"
    sh.printbody ''
  end

  function sh.printbody(txt)
    if cols then
      local l = ' | '
      stdout:write(l)
      stdout:write((txt:sub(0,cols - l:len())))
    else
      stdout:write(txt)
    end
    stdout:write '\n'
  end

  function sh.printfoot(txt)
    if cols then
      if txt then
        local l, r = ' |_ ', ' '
        txt = l .. txt:sub(0,cols - l:len()) .. r
        stdout:write(txt)
        stdout:write(string.rep('_', cols - txt:len()))
      else
        local l = ' |_'
        stdout:write(l)
        stdout:write(string.rep('_',cols - l:len()))
      end
    else
      stdout:write "\n"
      stdout:write(txt)
    end
    stdout:write '\n'
    stdout:write '\n'
  end
end

--[[
$ waxp.sh.screensize() : number, number
Get the screen rows,columns in chars defaulting to 25, 80
--]]
function sh.screensize()
  local p,s = io.popen('stty size')
  if p then
    s = p:read() p:close()
    return s:match('(%d+) (%d+)')
  end
  return 25,80
end

--[[
$ waxp.sh.rexec(command: string, ...: string) : table, number
Execute command and returns its contents on a table and its numeric exit
--]]
function sh.rexec(cmd, ...)
  local cs = {...}
  if #cs > 0 then
    cmd = cmd:format(unpack(cs))
  end

  local proc = io.popen(cmd..';echo $?')
  local lp, lc
  local r = {}
  if proc then
    while true do
      lp = lc
      lc = proc:read()
      rc = 1
      if lc then
        if lp then r[rc] = lp end
        rc=rc+1
      else
        if lp then
          return r, lp
        else
          return r, 1
        end
      end
    end
  else
    return r, 1
  end
end


--[[
$ waxp.sh.exec(command: string, ...: string)
Execute command and if it has errors abort Lua script
--]]
function sh.exec(cmd, ...)
  local cs = {...}
  if #cs > 0 then
    cmd = cmd:format(unpack(cs))
  end

  if DEBUG then print("EXEC "..cmd) end
  local proc = io.popen(cmd..';echo $?')
  local line, curr = nil, nil
  while true do
    line = curr
    curr = proc:read()
    if curr then
      if line then
        sh.printbody(line)
      end
    else
      if line ~= '0' then
          sh.printbody ''
          sh.printfoot ([[/!\ Exit ]]..line..[[ /!\]])
          os.exit(tonumber(line))
      end
      return
    end
  end
end

--[[
$ waxp.sh.whereis(cmd: string)
Find the command in system using the single field `pattern` filled with
subsequent string parameters.
--]]
function sh.whereis(cmd)
  for _,dir in ipairs(sh.PATH) do
    local f = dir..'/'..cmd
    local fh = io.open(dir..'/'..cmd, 'r')
    if fh ~= nil then
      io.close(fh)
      return f
    end
  end
end


--[[
$ waxp.sh.OS : string
sh.OS = sh.rexec("uname -s")[1];
--]]


--[[
$ waxp.sh.TERM : string
--]]
sh.TERM = os.getenv("TERM") or ""


--[[
$ waxp.sh.PATH : table
--]]
do
  local env, i, r = os.getenv("PATH"), 1, {}
  for p in env:gmatch("([^:]+)") do r[i], i = p, i+1 end
  sh.PATH = r
end
return sh
