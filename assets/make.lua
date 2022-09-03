local make = {}

unpack = unpack or table.unpack

local DEBUG = os.getenv('DEBUG')


function help(actions)
  print("Available actions:")
  for action,v in pairs(actions) do
    if type(v) == 'function'
      then print(action, actions[action..'_help'] or '')
    end
  end
end

--@ make.rexec( string command, table values) : table result, number exitstatus
--| Execute command and returns its contents on a table and its numeric exit
function make.rexec(cmd, ...)
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

--@ make.exec(string command, table values)
--| Execute command and if it has errors abort Lua script
function make.exec(cmd, ...)
  local cs = {...}
  if #cs > 0 then
    cmd = cmd:format(unpack(cs))
  end

  if DEBUG then print("EXEC "..cmd) end
  local proc = io.popen(cmd..';echo $?')
  local prev, curr = nil, nil
  if proc then
    while true do
      prev = curr
      curr  = proc:read()
      if curr then
        if prev then
          print(' | '..prev)
        end
      else
        if prev ~= "0" then
          print("\n\n//// Exit Status", prev,"\n\n")
          prev = prev or 1
          os.exit(prev)
        end
        return
      end
    end
  else
    os.exit(1)
  end
end


function make.whereis(cmd, ...)
  local targets = {}
  local cs = {...}
  if #cs > 0 then
    for _,v in ipairs(cs) do
      table.insert(targets,cmd:format(v))
    end
  else
    targets[1] = cmd
  end

  for _,v in ipairs(make.PATH) do
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

function make.getpath()
  local path = {}
  local syspath = os.getenv("PATH")
  local P=1;
  for p in syspath:gmatch("([^:]+)") do
    path[P] = p
    P = P+1
  end
  return path
end

function make.run(actions)
  if arg[1] and type(actions[arg[1]]) == "function" then
    actions[arg[1]]()
  else
    help(actions)
  end
end
make.PATH = make.getpath()
make.OS = make.rexec("uname -s")[1];
make.SED = make.whereis("%ssed","","g")
make.PWD = make.rexec("realpath .")[1];
make.TERM = os.getenv("TERM") or ""
return make
