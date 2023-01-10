--| # wax.json
--| Create and parse JSON file to/from Lua tables.

--{
local json = require 'wax.json'
--}


--$ wax.json.encode( t: {} ) : string
--| Convert the table `t` into a JSON string.
do

local res = json.encode { 10, true, { a="hi" }, 1/0, json.null}
assert( res == '[10,true,{"a":"hi"},null,null]')

end

--$ wax.json.decode( jsonstr: string) : table
--| Convert the `jsonstr` string into a Lua table.
do
--{
--| Every non array or object is converted to respective Lua
--| counterpart:
assert(json.decode[["hi"]] == "hi")
assert(json.decode[[null]] == json.null)
assert(json.decode[[10.9]] == 10.9)
assert(json.decode[[109]]  == 109)
assert(json.decode[[true]] == true)
assert(json.decode[[false]] == false)

local object = json.decode([[{
  "str":"A string", "num":10.667, "int":70999,
  "boot": true, "boof": false, "nul":null,
  "arr":["a", "b"], "obj":{"k":"v"}
}]])
assert(object.str   == 'A string')
assert(object.num   == 10.667)
assert(object.int   == 70999)
assert(object.boot  == true)
assert(object.boof  == false)
assert(object.nul   == json.null)
assert(#object.arr  == 2)
assert(object.obj.k == "v")
--}
end


-- Encode test for deep nested objects
-- Decoding a JSON with 1000+ nesting levels
do
  local levels = 1000
  local srcstr = { '{', table.concat ({
    [=["Strings":["A str","Acentuação"]]=],
    [=["Números":[10.667,70999,-1]]=],
    [=["Boolean":[true,false]]=],
    [=["Null":null]=]
  },',') }
  srcstr[3] = ','
  srcstr[4] = ('"atenção":{'):rep(levels)
  srcstr[5] = srcstr[2]
  srcstr[6] = ('}'):rep(levels)
  srcstr[7] = '}'

  local source = table.concat(srcstr)
  local decoded = json.decode(source)
  local encoded = json.encode(decoded)
  local redecoded = json.decode(encoded)

  -- Type property
  assert(type(decoded)   == 'table')
  assert(type(encoded)   == 'string')
  assert(type(redecoded) == 'table')

  -- Key/Value equivalence property (1st level)
  for k,v in pairs(decoded) do
    local t = type(v)
    assert(type(redecoded[k]) == t)
    if t ~= 'table' then
      assert(v == redecoded[k])
    end
  end

  -- Innermost equivalence property (most nested)
  for i=1, levels, 1 do
    decoded,redecoded = decoded['atenção'], redecoded['atenção']
  end

  for k,v in pairs(decoded) do
    local t = type(v)
    assert(type(redecoded[k]) == t)
    if t ~= 'table' then
      assert(v == redecoded[k])
    end
  end
  assert(decoded.Strings[1] == "A str")
  assert(decoded.Strings[2] == "Acentuação")
  assert(decoded.Strings[3] == nil)

  assert(decoded['Números'][1] == 10.667)
  assert(decoded['Números'][2] == 70999)
  assert(decoded['Números'][3] == -1)
  assert(decoded['Números'][0] == nil)

  assert(decoded.Boolean[1] == true)
  assert(decoded.Boolean[2] == false)

  assert(decoded.Null == json.null)
end

-- Deep nested arrays
-- Decoding/Encoding a JSON array containing 5000+ items
do
  local arrayex = '["quá","qué","quí"]'
  local levels = 1000
  source = table.concat{
    ('['):rep(levels),(arrayex..','):rep(levels),arrayex,
    (']'):rep(levels-1),
    ',"a",true,null]'
  }
  local decoded = json.decode(source)
  local encoded = json.encode(decoded)
  local redecoded = json.decode(encoded)

  -- Key/Value equivalency property (1st level)
  for i,v in ipairs(decoded) do
    local t = type(v)
    assert(type(redecoded[i]) == t)
    if t == 'table' then
      assert(#v == 1 and #redecoded[i] == 1)
    else
      assert(v == redecoded[i])
    end
  end

  -- Order property
  assert(source == encoded)

end

-- Encode test for deep nested objects
do
  local t = {a={b={c={d={e={f={g={h={i={j={
    k={"hello", "world"}
  }}}}}}}}}}}
  t = {a={b={c={d={e={f={g={h={i={j=t}}}}}}}}}}
  t = {a={b={c={d={e={f={g={h={i={j=t}}}}}}}}}}
  t = {a={b={c={d={e={f={g={h={i={j=t}}}}}}}}}}
  t = {a={b={c={d={e={f={g={h={i={j=t}}}}}}}}}}
  t = {a={b={c={d={e={f={g={h={i={j=t}}}}}}}}}}
  t = {a={b={c={d={e={f={g={h={i={j=t}}}}}}}}}}
  t = {a={b={c={d={e={f={g={h={i={j=t}}}}}}}}}}
  t = {a={b={c={d={e={f={g={h={i={j=t}}}}}}}}}}
  t = {a={b={c={d={e={f={g={h={i={j=t}}}}}}}}}}
  t.z = 10
  local encoded = json.encode(t);
  local decoded = json.decode(encoded)
  local nested = decoded
  nested = nested.a.b.c.d.e.f.g.h.i.j
  nested = nested.a.b.c.d.e.f.g.h.i.j
  nested = nested.a.b.c.d.e.f.g.h.i.j
  nested = nested.a.b.c.d.e.f.g.h.i.j
  nested = nested.a.b.c.d.e.f.g.h.i.j
  nested = nested.a.b.c.d.e.f.g.h.i.j
  nested = nested.a.b.c.d.e.f.g.h.i.j
  nested = nested.a.b.c.d.e.f.g.h.i.j
  nested = nested.a.b.c.d.e.f.g.h.i.j
  nested = nested.a.b.c.d.e.f.g.h.i.j.k
  assert(nested[1] == "hello"
     and nested[2] == "world"
     and nested[3] == nil)
  assert(decoded.z == 10)
end

