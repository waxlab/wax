-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

-- Simple functions to handle basic system commands usually used
-- via shell scripts;


local sh = {}

unpack = unpack or table.unpack

local DEBUG = os.getenv('DEBUG')


--$ sh.printhead(txt:text)
--$ sh.printbody(txt:body)
--$ sh.printfoot(txt:foot)
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




--$ sh.screensize() : number, number
--| Get the screen rows,columns in chars defaulting to 25, 80
function sh.screensize()
  local p,s = io.popen('stty size')
  if p then
    s = p:read() p:close()
    return s:match('(%d+) (%d+)')
  end
  return 25,80
end


--$ sh.rexec(command: string, ...: string) : table, number
--| Execute command and returns its contents on a table and its numeric exit
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

--$ sh.exec(command: string, ...: string)
--| Execute command and if it has errors abort Lua script
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

--$ sh.whereis(pattern: string, ... : string)
--| Find the command in system using the single field `pattern` filled with
--| subsequent string parameters.
--|
--| Ex:
--|
--| ```lua
--| sh.whereis('lua%s','51','5.1') -- matches `lua51` and `lua5.1`
--| sh.whereis('%ssed','','g') -- matches `sed` and `gsed`
--| ```
function sh.whereis(cmd, ...)
  local targets = {}
  local cs = {...}
  if #cs > 0 then
    for _,v in ipairs(cs) do
      table.insert(targets,cmd:format(v))
    end
  else
    targets[1] = cmd
  end

  for _,v in ipairs(sh.PATH) do
    for _,w in ipairs(targets) do
      local f = v .. '/' .. w
      local fh = io.open(f,'r')
      if fh ~= nil then
        io.close(fh)
        return f
      end
    end
  end
end

function sh.getpath()
  local path = {}
  local syspath = os.getenv("PATH")
  local P=1;
  for p in syspath:gmatch("([^:]+)") do
    path[P] = p
    P = P+1
  end
  return path
end

sh.PATH = sh.getpath()
sh.OS = sh.rexec("uname -s")[1];
sh.SED = sh.whereis("%ssed","","g")
sh.PWD = sh.rexec("realpath .")[1];
sh.TERM = os.getenv("TERM") or ""
return sh
