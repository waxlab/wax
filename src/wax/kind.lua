local wax = require 'wax'
local push, pop = table.insert, table.remove

local kind = {
  ['boolean' ] = {t='boolean' },
  ['function'] = {t='function'},
  ['number'  ] = {t='number'  },
  ['string'  ] = {t='string'  },
  ['table'   ] = {t='table'   },
  ['thread'  ] = {t='thread'  },
  ['userdata'] = {t='userdata'}
}
kind.s = kind.string
kind.n = kind.number
kind.t = kind.table
-- Accessories
local walk, step, ast
-- Tokens
local tokens,    solveData
    , tkQuote,   tkSep
    , tkTable,   tkTableEnd, tkPair
    , tkFnGroup, tkFnGroupEnd

function tkQuote(R, str, len, pos, data, tk)
  if data then return nil, pos, 'Unexpected quote' end
  local exp = tk == "'" and [[(\*)']] or [[(\*)"]]
  local p,m,_ = pos
  while p < len do
    _,p,m = str:find(exp, p)
    if not p then return nil, pos, 'Unclosed string' end
    if m and #m % 2 == 0 then
      R[#R+1] = {t='eq', v=str:sub(pos, p-1)}
      return true, p+1
    end
    p=p+1
  end
  return nil, pos, 'Unclosed string'
end

function tkTable(R, str, len, pos, data, tk) -- luacheck: ignore 212
  local tbl = {t='table', v={}}
  local msg, ok

  if data then
    return nil, pos, 'Unexpected '..tkTable
  end

  ok, pos, msg = walk(tbl, str, len, pos, tkTableEnd)
  if R.t == 'table' then
    push(R.v, tbl)
  else
    push(R, tbl)
  end
  return ok, pos, msg
end

function tkSep(R, str, len, pos, data, tk)
  if R.t == 'table' then
    return tkTableEnd(R, str, len, pos, data, tk)
  -- Adicionar checagens quando for uma função.
  -- Outros casos devem incorrer em erro
  -- else
  --   if data and not R[1] then
  --     push(R.v, data)
  --   elseif not data and R[1] then
  --     push(R.v, pop(R))
  --   else
  --     return nil, pop, 'Unexpected '..tokens[tkSep]
  --   end
  --   if R.unpaired then -- x:y as x being a doc name and y the kind
  --     R[-#R] = R.unpaired
  --   end
  --
  elseif R.t == 'function' then
    return tkFnGroupEnd(R, str, len, pos, data, tk)
  end
  R.unpaired = nil
  return true, pos
end

function tkPair(R, str, len, pos, data, tk) -- luacheck: ignore 212
  if R.t == 'table' then
    if data then
      -- if has data, cannot have pending item or key
      if not R[1] and not R.unpaired then
        R.unpaired = solveData(data)
        return true, pos
      end
      return nil, pos, 'Expected '..tokens[tkSep]..' or '..tokens[tkTableEnd]
    else
      -- otherwise must have a pending item but not pending key
      if R[1] and not R.unpaired then
        R.unpaired = pop(R)
        return true, pos
      end
    end
  end
  return nil, pos, 'Unexpected '..tkPair
end

function tkTableEnd(R, str, len, pos, data, tk) -- luacheck: ignore 212
  if R.t == 'table' then
    if R.unpaired then -- x:y as x being the key and y being the value kind
      if data then
        R.v[R.unpaired] = solveData(data)
      elseif R[1] then
        R.v[R.unpaired] = pop(R)
      else
        return nil, pos, 'Unexpected '..tk..' after unpaired key'
      end
      R.unpaired = nil
    else
      if data and not R[1] then
        push(R.v, solveData(data))
      elseif not data and R[1] then
        push(R.v, pop(R))
      end
    end
  end
  return true, pos
end

function solveData(data)
  if kind[data] then return kind[data] end
  if tonumber(data) then
    return { t='eq', v=tonumber(data) }
  elseif data:match('^true$') then
    return { t='eq', v=true }
  elseif data:match('^false$') then
    return { t='eq', v=false }
  end
end

function tkFnGroup(R, str, len, pos, data, tk)
  local msg, ok
  if data ~= nil then
    return nil, pos, 'Unexpected '..tk
  end

  local fun = {t='function', a={}, r={}}
  ok, pos, msg = walk(fun, str, len, pos, tkFnGroupEnd)
  if not ok then return ok, pos, msg end

  for i,v in ipairs(fun) do
    fun.a[i] = v
    fun[i] = nil
  end

  local _,r = str:find('^%s*%->%s*%(',pos)
  if not r then return nil, pos 'Missing the kind of function return' end

  ok, pos, msg = walk(fun, str, len, r+1, tkFnGroupEnd)
  if not ok then return ok, pos, msg end

  for i,v in ipairs(fun) do
    fun.r[i] = v
    fun[i] = nil
  end
  push(R, fun)
  return ok, pos, msg
end

function tkFnGroupEnd(R,_,_,pos,data)
  if data ~= nil then
    push(R, solveData(data))
  end
  return true, pos
end





--$ step(str:s, len:n, pos:n)(pos:n, data:s|n, tk:s|n)
function step(str, len, pos)
  local l, r, tk = str:find('%s*([^@.%w])%s*', pos)
  l, r = l and l-1 or len, r and r+1 or len+1
  local data = l>=pos and str:sub(pos, l) or nil
  return r, data, tk
end

--$ walk(R:t, str:s, len:n, start:n, delim:s) (R:t, pos:n)
--$ ! walk() (nil, pos:n, err:s)
function walk(R, str, len, start, delim)
  local ok, pos, data, tk, E = true, start
  while ok and pos <= len do
    pos, data, tk = step(str, len, pos)
    if tk then
      if delim and tokens[tk] == delim then
        return tokens[tk](R, str, len, pos, data, tk)
      elseif tokens[tk] then
        ok, pos, E = tokens[tk](R, str, len, pos, data, tk)
      else
        pos = str:find(tk,pos,true)
        return nil, pos, 'Token '..tk..' not found'
      end
    else
      R[#R+1] = solveData(data)
      return R, len+1
    end
  end
  return ok, pos, E
end


function ast(str)
  if type(str) ~= 'string' then error('ast arg #1: string expected',2) end

  local sign, ok, pos, E = {}
  ok, pos, E = walk(sign, str, #str, 1)
  if not ok then
    return nil, ('%s\nError at character %d: %q'):format(str, pos, E)
  end
  return not sign.t and sign[1] or sign
end
kind.ast = ast


tokens = {
  ['"'] = tkQuote,
  ["'"] = tkQuote,
  ['{'] = tkTable,
  [':'] = tkPair,
  ['}'] = tkTableEnd,
  ['('] = tkFnGroup,
  [')'] = tkFnGroupEnd,
  [','] = tkSep,
  [tkTable]    = '{',
  [tkPair]     = ':',
  [tkTableEnd] = '}',
  [tkSep]      = ','
}

return kind
