--| # wax.json
--| Module for JSON handling.

--{
local json = require 'wax.json'
--}

--$ wax.json.encode( t: {} ) : string
--| Convert the table `t` into a JSON string.
do
local res = json.encode({
  a = "A",
  b = "B",
  c = "C",
  d = "D"
})
print('---->', res);
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


--| ###### Deep objects test
--| Decoding a JSON with 1000+ nesting levels
do
--{
  local jnest10 = {[["a":{"b":{"c":{"d":{"e":{"f":{"g":{"h":{"i":{"j":{]],[[}}}}}}}}}}]]}
  local jtarget = [["nested":"nested value"]]
  local jnest = {jnest10[1]:rep(100),jnest10[2]:rep(100)}

  local jexample = [[
    "str":"A string", "num":10.667, "int":70999,
    "boot": true, "boof": false, "nullval":null,
    "arr":["z","x","y",2000],]]
  local jsonstr = table.concat({'{',jexample,jnest[1],jtarget,jnest[2],'}'})
  local res = json.decode(jsonstr)

  local nst = res
  for i=1, 100, 1 do nst = nst.a.b.c.d.e.f.g.h.i.j end

  assert(type(res)   == 'table')
  assert(res.str     == "A string")
  assert(res.num     == 10.667)
  assert(res.int     == 70999)
  assert(res.boot    == true)
  assert(res.boof    == false)
  assert(res.nullval == json.null)
  assert(type(nst)   == 'table')
  assert(#res        == 0)
  assert(#res.arr    == 4)
  assert(res.arr[4]  == 2000)
  assert(nst.nested  == "nested value")
--}
end

--| ###### Large arrays test
--| Decoding a JSON array containing 5000+ items
do
--{
local arrayex = '["quá", "qué", "quí"]'
local res = json.decode(arrayex)
assert(type(res) == 'table')
assert(#res == 3)


local res = json.decode(
  table.concat{'[',(arrayex..','):rep(5000),arrayex,']'}
)
assert(#res         == 5001)
assert(#res[5001]   == 3)
assert(res[5001][3] == 'quí')
--}
end
