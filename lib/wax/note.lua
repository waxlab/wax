local note = {}

function note.self(ctx)
  ctx = ctx and ctx+2 or 2
  local src = debug.getinfo(ctx)
  if src then src = src.short_src end
  local f = io.open(src)
  if f then
    local t = {}
    repeat
      line = f:read()
      if line and line:find('^%-%-[|${}]%s?') == 1 then
        if line:sub(3,3) == '@' then
          t[#t+1] = '\n> '..line:sub(5)
        else
          t[#t+1] = line:sub(5)
        end
      end
    until not line
    f:close()
    return table.concat(t,'\n')
  else
    return ''
  end
end

return note
