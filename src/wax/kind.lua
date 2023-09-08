-- lua check:: ignore 212 (unused arguments)

local wax = require 'wax'
local push, pop, tsub = table.insert, table.remove
local walk, step, ast
local kind, parse, tokens

local tkEnum           = '|'
local tkFuncGroupClose = ')'
local tkFuncGroupOpen  = '('
local tkQuoteDouble    = '"'
local tkQuoteSingle    = "'"
local tkSeparator      = ','
local tkTableClose     = '}'
local tkTableOpen      = '{'
local tkPair           = ':'
local tkFinish         = {}
-- tkFinish and tkMain use a unique table as ref for comparison 
-- so we not use a string neither a boolean which could be result
-- of a wrong test or decay from a test with another type.

local Ast = {
  err =
    function(self, e)
      self.error = e
      return nil
    end,
  top =
    function(self)
      return self[#self]
    end,
  bottom =
    function(self)
      return self[1] or self
    end,
}
function Ast.new(str)
  return setmetatable({
    str = str,
    len = #str,
    pos = 0,
    E   = false,
    {t='main'}
  }, Ast )
end
Ast.__index = Ast


kind = {
  ['boolean' ] = {t='boolean' },
  ['function'] = {t='function'},
  ['number'  ] = {t='number'  },
  ['string'  ] = {t='string'  },
  ['table'   ] = {t='table'   },
  ['thread'  ] = {t='thread'  },
  ['userdata'] = {t='userdata'}
}

parse = {
  enum = function(R, tk)
    local node, parent
    node = R:top()

    -- Needs a previous value (it is infix)
    if #node == 0 then
      R:err 'Missing enum value'
      return
    end

    -- Create
    if tkEnum == tk and node.t ~= 'enum' then
      push(R, {t='enum', v={pop(node)}})
      return true
    end

    -- Add item
    push(node.v, pop(node))

    -- Finish
    if tkEnum ~= tk then
      pop(R)
      parent = R:top()
      push(parent, node)
      if parent.t == 'main'
        then return true
        else return parse[parent.t](R, tk)
      end
    end
    return true
  end,

  func = function(R, tk)
    local node = R:top()
    -- Create the function kind
    if tk == tkFuncGroupOpen then
      if #node > 0 then return R:err 'Unexpected function' end
      push(R, {t='func', a={}})
      return true
    end

    if tkFinish == tk then
      return R:err 'Unfinished function'
    end

    if node.t ~= 'func' then
      if node.t == 'main'          then return R:err 'Unfinished function' end
      return parse[node.t](R, tk)
    end

    -- Push last content
    if tkSeparator == tk then
      if #node == 0 then
        if node.r
          then return R:err 'Missing function return spec item'
          else return R:err 'Missing function argument spec item'
        end
      end
      push(node.r or node.a, pop(node))
      return true
    end

    if tkFuncGroupClose == tk then
      if #node > 0 then
        push(node.r or node.a, pop(node))
      end
      if not node.r then
        local _,r = R.str:find('^%s*%->%s*%(',R.pos)
        if not r then return R:err 'Unexpected function end' end
        R.pos, node.r = r+1, {}
      else
        pop(R)
        push(R:top(), node)
      end
      return true
    end
  end,

  quote = function(R, tk)
    local node = R:top()
    if #node > 0 then
      R:err('Unexpected quote')
    end
    local exp = tk == "'" and [[(\*)']] or [[(\*)"]]
    local pos, len, str, m, _ = R.pos, R.len, R.str

    while pos <= len do
      _,pos,m = str:find(exp, pos)
      if not pos then return R:err 'Unclosed string' end
      if m and #m % 2 == 0 then
        push(node, {t = 'eq', v = str:sub(R.pos, pos-1)})
        R.pos = pos+1
        return true
      end
      pos = pos+1
    end

    R:err 'Unclosed string'
    return false
  end,

  separator = function(R, tk)
    parse[R:top().t](R, tk)
  end,

  table = function(R, tk)
    local node = R:top()

    if tkTableOpen == tk then
      if #node > 0 then return R:err 'Unexpected table opening' end
      push(R, {t='table', v={}})
      return true
    end

    if tkFinish == tk then
      return R:err 'Unfinished table'
    end

    while node.t ~= 'table' do
      if node.t == 'main'         then return R:err 'Unfinished table' end
      if not parse[node.t](R, tk) then return end
      node = R:top()
    end

    -- From here... node.t == 'table'

    if tkPair == tk then
      if node.key ~= nil then return R:err 'Unfinished pair' end
      if #node == 0      then return R:err 'Missing left hand pair value' end
      node.key = pop(node)
      return true
    end

    if tkSeparator == tk then
      if #node == 0 then return R:err 'Missing table value' end
      if node.key
        then node.v[node.key], node.key = pop(node), nil
        else push(node.v, pop(node))
      end
      return true
    end

    if tkTableClose == tk then
      -- For pending pair
      if node.key then
        if #node == 0 then return R:err 'Missing right hand pair value' end
        node.v[node.key], node.key = pop(node), nil
      -- It may be an empty table so...
      elseif #node > 0 then
        push(node.v, pop(node))
      end
      pop(R)
      push(R:top(), node)
      return true
    end
    return R:err 'Invalid token on table scope'
  end,

}

tokens = {
  [tkEnum]           = parse.enum,
  [tkQuoteSingle]    = parse.quote,
  [tkQuoteDouble]    = parse.quote,
  [tkFuncGroupOpen]  = parse.func,
  [tkFuncGroupClose] = parse.func,
  [tkSeparator]      = parse.separator,
  [tkTableOpen]      = parse.table,
  [tkTableClose]     = parse.table,
  [tkPair]           = parse.table
}

function walk(R)
  local tk
  local len = R.len
  while not R.E and R.pos <= len do
    tk = step(R)

    if not tk then return true end
    if tokens[tk] then
      tokens[tk](R, tk)
    else
      return R:err('Token '..tk..' not found')
    end
  end
end

function step(R)
  local left, right, tk = R.str:find('([^@.%w%s])', R.pos)
  local top = R:top()
  if not tk then
    left = R.len+1
    right = left
  end

  local buf = R.str
      :sub  (R.pos, left-1)
      :gsub ('^%s*','')
      :gsub ('%s*$','')

  if buf ~= '' then
    if pop(top) then
      return R:err 'Expected token'
    end
    local num = tonumber(buf)
    local val = kind[buf]
      or  ( buf:match('^true$')  and { t='eq', v=true } )
      or  ( buf:match('^false$') and { t='eq', v=false } )
      or  ( num and { t = 'eq', v=num } )
      or  buf

    push (top,val)
  end
  R.pos = right+1
  return tk
end



function ast(str)
  if type(str) ~= 'string' then error('ast arg #1: string expected',2) end

  local R = Ast.new(str)
  if not walk(R) and R.E
    then return nil
        , ('%s\nError at character %d: %q')
          : format(R.str, R.pos, R.E or 'Error on R.E')
  end

  local node = R:top()
  while node.t ~= 'main' do
    parse[node.t](R, tkFinish)
    node = R:top()
  end
  return pop(node)
end


kind.ast = ast
return kind
