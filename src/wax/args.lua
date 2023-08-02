-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors


local out = io.stdout

local E_shortfmt = [[Spec #%d (%q): has invalid short option name]]
local E_longfmt  = [[Spec #%d (%q): has invalid long option name]]
local E_longrep  = [[Spec #%d (%q): duplicates long option name]]
local E_shortrep = [[Spec #%d (%q): duplicates short long name]]
local E_switchnmul = [[Spec #%d (%q): switchs cannot be multiple]]
local E_switchnset = [[Spec #%d (%q): switchs cannot have a set of values]]
local E_switchnreq = [[Spec #%d (%q): switchs cannot be mandatory]]

local HINT_restrict = '--%s must have one of these values:\n * %s'
local HINT_invalid  = 'Invalid option %q, see --help for more'
local HINT_required   = [[option --%s must be informed]]

local concat, insert, remove = table.concat, table.insert, table.remove


local
function HELP_print(header, rules)
  out:write '\n' out:write(header) out:write '\n'
  local value
  for _,r in ipairs(rules) do
    if r.set then
      value = concat(r.default, '|')
    elseif r.multi then
      value = 'value'
    else
      value = 'value'
    end

    out:write '  '
    if r.short then
        out:write('-'..r.short)
        if r.long then out:write ', ' end
    end
    if r.long then out:write('--'..r.long) end
    if not r.switch and value then out:write(' <'..value..'>') end
    if not r.switch and r.default then
      local tdef = type(r.default)
      out:write(' (default: ')
      if tdef == 'function'
        then out:write(r.default())
      elseif tdef == 'table'
        then out:write(r.default[#r.default])
        else out:write(r.default)
      end
      out:write(')')
    end
    out:write(r.desc and ('\n        '..r.desc..'\n') or '\n')
  end
  out:write '\n'
end


local
function help(spec, hint)
  local required, optional = {}, {}
  for _, rule in ipairs(spec.all) do
    if rule.required
      then required[#required+1]=rule
      else optional[#optional+1]=rule
    end
  end
  if #required > 0 then HELP_print('REQUIRED PARAMETERS', required) end
  if #optional > 0 then HELP_print('OPTIONS', optional) end
end


local
function hint(spec, msg, ...)
  return nil, function() help(spec) end, msg:format(...)
end


-- expand grouped short options from a single argument into various
-- including the ones with glued value
local
function parse_short(arg, idx, spec, oname)
  local chars, charidx, char, rule = #oname

  -- If only one letter doesn't need to be treated here...
  if chars == 1 then return spec.short[oname], oname end

  -- The actual index will be replaced by the first expanded...
  remove(arg, idx)

  -- Treats each letter
  charidx=1
  while charidx <= chars do
    char = oname:sub(charidx, charidx):match('%w')
    rule = spec.short[char]

    -- Abort if option is not supported
    if not rule then return nil, char end
    insert(arg, idx, '-'..char)
    idx, charidx = idx+1, charidx+1

    -- If option is not a switch, treat all remaining charaters a its value
    if not rule.switch and charidx <= chars then
      insert(arg, idx, oname:sub(charidx))
      idx, charidx = idx+1, chars+1 -- jump to the end to abort while.
    end
  end
  char = oname:sub(1,1)
  return spec.short[char], char
end


--[=[
  $ parse_args (R:table, arg:table, idx:number, spec:table, rule:table)

  Tail call recursive. Simpler this way than with while...

  R is the accumulator through recursion, dict part contains the options and
  list part contains the non-options.

  If ``rule`` a table, the function looks for the value represented by the rule,
  otherwise it looks for another option.
--]=]
local
function parse_args(R, arg, idx, spec, rule)
  local argitem, odash, oname

  argitem = arg[idx]
  if not argitem then return R end

  -- Try to get short or long option name
  if not rule then
    odash, oname = argitem:match '^(%-%-?)(.*)$'

    -- stop parsing after a unamed ``--`` or after first no option/value
    if not odash or odash == '--' and oname == '' then
      local rnum = 1
      idx = odash and idx+1 or idx
      while arg[idx] do
        R[rnum], rnum, idx = arg[idx], rnum+1, idx+1
      end
      return R
    end

    if odash == '--'
      then rule = spec.long[oname]
      else rule, oname = parse_short(arg, idx, spec, oname)
    end

    if not rule
      then return hint(spec, HINT_invalid, oname)
    elseif rule.switch
      then R[rule.name], rule = not rule.default, nil
    end

    return parse_args(R, arg, idx+1, spec, rule)
  end

  -- value from item set
  if rule.set then
    for _,value in ipairs(rule.default) do
      if argitem == value then
        R[rule.name] = argitem
        return parse_args(R, arg, idx+1, spec)
      end
    end
    return hint(spec, HINT_restrict, rule.long, concat(rule.default,'\n * '))
  elseif rule.multi then
    if not R[rule.name]
      then R[rule.name] = {argitem}
      else R[rule.name][#R[rule.name]+1] = argitem
    end
  else
    R[rule.name] = argitem
  end
  return parse_args(R, arg, idx+1, spec)
end


local
function parse_spec(spec)
  local long, short, switch = {}, {}
  for n, rule in ipairs(spec) do
    rule.long, rule.short, switch = rule[1], rule[2], rule[3]
    local name = rule[1] or rule[2]
    if switch then
      rule.required = switch:find('!',1,true)
      rule.multi    = switch:find('+',1,true)
      rule.switch   = switch:find('-',1,true)
    end
    rule.name = name
    rule.set  = type(rule.default) == 'table'

    if rule.switch then
      if rule.multi    then error( E_switchnmul:format(n, name) ) end
      if rule.set      then error( E_switchnset:format(n, name) ) end
      if rule.required then error( E_switchnreq:format(n, name) ) end
    end

    if rule.long then
      assert(rule.long:match '^%w[%w-_]*$', E_longfmt:format(n, rule.long))
      assert(long[rule.long] == nil, E_longrep:format(n, rule.long))
      long[rule.long] = rule
    end
    if rule.short then
      assert(rule.short:match '^%w$', E_shortfmt:format(n, rule[2]))
      assert(rule.short[rule[2]] == nil, E_shortrep:format(n, rule[2]))
      short[rule[2]] = rule
    end
  end
  return {long=long, short=short, all=spec}
end

-- wax.args
return function (spec, arg, idx)
  assert(type(spec) == 'table')
  spec = parse_spec(spec)
  local res, fn, msg = parse_args({}, arg, idx or 1, spec)
  if not res then return res, fn, msg end

  -- Adds default values and checks for required.
  for _, rule in ipairs(spec.all) do
    if res[rule.name] == nil then
      if rule.required then
        return hint(spec, HINT_required, rule.name)
      elseif rule.set then
        local default = rule.default[#rule.default]
        res[rule.name] = rule.multi
          and {default}
          or  default
      else
        res[rule.name] = type(rule.default) == 'function'
          and rule.default(res)
          or rule.default
      end
    end
  end
  return res, function() help(spec) end
end
