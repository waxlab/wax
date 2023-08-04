-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors
local wax = require 'wax'

local signatures = {}

-- Helper functions
local loadfile, expected, step, walk, identify, tokenize, push

-- Token functions/representation
local tkSpace, tkName, tkValue, tkKindId, tkFunc, tkFuncC, tkTable
    , tkTableC, tkOr, tkSep, tkImply, tkSelf, tkNil

-- Data
local symbols

--:::::::::--
-- HELPERS --
--:::::::::--

function loadfile(filename)
    local f = io.open(filename,'r')
    local line = f:read()
    local res,r,capt,cont = {},0,false,false
    while line do
      if not capt
        then capt = line:match('^%s*%-%-%[%[')
      elseif line:match('^%s*%-%-%]%]')
        then capt = nil
      elseif line:match('^%s*$')
        then cont = false
      else local m = line:match('^%s*%$%s*(.*)$')
        if m then
          cont, r = true, r+1
          res[r] = (res[r] or '')..m
        elseif cont then
          res[r] = res[r]..line:gsub('^%s*',' ')
        end
      end
      line = f:read()
    end
    f:close()
    return res
  end

function push(ctx, ref, name)
    local s = #ctx+1
    if name then ctx[-s] = name end
    ctx[s] = ref
  end

-- (string:S, pos:S -> name:S, ref:S, sym:S, pos:N)
function step(str, pos)
    local left, right, sym = str:find('%s*([^%w%s%.@:]+)%s*', pos)
    local kind = str:sub(pos, sym and left-1 or nil)
    local name, ref
    name, ref = kind:match '^([%l%u_]%w*):(.*)$'
    ref = ref or
      kind:match '^(%.?[%l%u][%w%.]*)$' or
      kind:match '^(%.?[%l%u][%w%.]+%.@[%l%u]%w*)$' or
      kind:match '^%.@[%l%u]%w+$'
    pos = right and right+1
    print('RNSP',ref, name, sym, sym and symbols[sym], pos)
    return ref, name, symbols[sym], pos
  end

function walk(ctx, str, len, pos, tkEnd)
    local ref, name, sym
    ref, name, sym, pos = step(str,pos)

    if tkEnd and sym == tkEnd then
      pos = tkEnd(ctx, str, len, pos, ref, name)
      return pos, true
    end

    if sym then
      if sym == tkEnd then return pos end
      if sym then
        pos = sym(ctx, str, len, pos, ref, name)
      else
        error('invalid token')
      end
    else
      if pos and pos < len then
        print('----->', ref, sym)
        error('Expected end of signature after '..ref..' '..symbols[sym])
      end
      tkNil(ctx, str, len, pos, ref, name)
    end
    return pos
  end

function identify(str)
    local _, r, id = str:find('^(%S+)%s*=%s*')
    return id, r+1
  end

function tokenize(str)
    local len, id, pos = #str, identify(str)
    local ctx = {}
    if signatures[id] then
      table.insert(signatures[id], ctx)
    else
      signatures[id] = {ctx}
    end
    while pos and pos < len do
      pos = walk(ctx, str, len, pos)
    end
    return ctx
  end

function expected(what, found, where)
    error (('\n\tSignature: %q\n\tExpects:   %q\n\tFound:     %q\n\n')
             :format(where, what, found),2)
  end


--::::::::--
-- TOKENS --
--::::::::--
-- This functions have a common signature and a common result
-- (ctx:t, str:s, len:n, pos:n, ref:s, name:s) -> pos:n

function tkFunc(ctx, str, len, pos, ref, name)
    if name or ref then error('error on function syntax') end
    local args, ret, stop
    print('tkFunc', pos, ref, name) -- DEBUG

    stop, args = false, {}

    while not stop and pos and pos < len do
      pos, stop = walk(args, str, len, pos, tkFuncC)
    end

    local res,name,sym,pos = step(str,pos)
    if res or name or sym ~= tkImply then error('Missing function arrow') end
    res,name,sym,pos = step(str,pos)
    if res or name or sym ~= tkFunc  then error('Missing function return') end

    stop, ret = false, {}
    while not stop do
      if pos and pos > len
        then error('Incomplete function return declaration')
      end
      pos, stop = walk(ret, str, len, pos, tkFuncC)
    end
    if ctx.t then
      local sub = {}
      table.insert(ctx, sub)
      ctx = sub
    end

    ctx.t = 'function'
    ctx.a = args
    ctx.r = ret
    ctx.s = '('..table.concat(args,', ')..') -> ('..table.concat(ret,', ')..')'
    return pos
  end

function tkImply(ctx, str, len, pos, ref, name)
    if ctx.type ~= 'function' then
      error('Unexpected "->" in ctxature')
    end
    return pos
  end

function tkFuncC (ctx, str, len, pos, ref, name)
    if ref then push(ctx, ref, name) end
    return pos
  end


function tkSpace (_, str, len, pos, _, _)
    if pos < len then
      return nil, expected('end of line', str:sub(pos), str)
    end
    return nil
  end

function tkOr (ctx, _, _, pos, ref, name)
    print('tkOr', ref, name)
    if not ctx.type then ctx.type = 'or' end
    if ctx.type ~= 'or' then
      error('Unexpected enum')
    end
    local p = #ctx+1
    ctx[p], ctx[-p] = ref, name
    return pos
  end

function tkNil (ctx, str, len, pos, ref, name)
    if ctx.type == 'enum' then
      return tkOr (ctx, str, len, pos, ref, name)
    end
    table.insert(ctx, ref)
  end


function tkName   (ctx, str, len, pos, ref, name) print "tkName"    return pos end
function tkValue  (ctx, str, len, pos, ref, name) print "tkValue"   return pos end
function tkKindId (ctx, str, len, pos, ref, name) print "tkKindId"  return pos end
function tkTable  (ctx, str, len, pos, ref, name) print "tkTable"   return pos end
function tkSep    (ctx, str, len, pos, ref, name)
  if ref then
    push(ctx, ref, name)
    return pos
  end
  error('Invalid separator ","')
end
function tkSelf   (ctx, str, len, pos, ref, name) print "tkSelf"    return pos end
function tkEnum   (ctx, str, len, pos, ref, name) print "tkEnum"    return pos end
function tkTableC () error('Unexpected "}" in ctxature') end


symbols = {
  ---- Symbol key space ----
  ['|']  = tkOr,
  ['(']  = tkFunc,
  [')']  = tkFuncC,
  ['->'] = tkImply,
  [':']  = tkSelf,
  [',']  = tkSep,
  [' ']  = tkSpace,
  ['{']  = tkTable,
  ['}']  = tkTableC,
  ['\t'] = tkSpace,
  ---- Name key space ----
  [tkOr]     = "tkOr",
  [tkFunc]   = "tkFunc",
  [tkFuncC]  = "tkFuncC",
  [tkImply]  = "tkImply",
  [tkSelf]   = "tkSelf",
  [tkSep]    = "tkSep",
  [tkSpace]  = "tkSpace",
  [tkTable]  = "tkTable",
  [tkTableC] = "tkTableC",
  [tkName]   = "tkName",
  [tkValue]  = "tkValue",
  [tkKindId] = "tkKindId",
}


return function(f, basename)
  local signatures = loadfile(f)
  local res = {}
  for i,sign in ipairs(signatures) do
    signatures[i] = tokenize(sign, basename)
    print(('::::::: %s :::::::'):format(sign)) wax.show(signatures[i]) -- DEBUG
  end
  wax.show(res)
end



--[=[
local tokens = {
  tkEnumC  = tkEnumC,
  tkEnum   = tkEnum,
  tkFuncC  = tkFuncC,
  tkFunc   = tkFunc,
  tkImply  = tkImply,
  tkKindId = tkKindId,
  tkName   = tkName,
  tkSep    = tkSep,
  tkSpace  = tkSpace,
  tkTableC = tkTableC,
  tkTable  = tkTable,
  tkValue  = tkValue,
}
]=]
