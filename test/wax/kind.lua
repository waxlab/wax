-- luacheck: ignore 311
local wax = require 'wax'
local at = wax.attest
local R



R = at( assert( wax.kind.ast '"quidproquo"'))


-- Primitives
do
-- {t='boolean'}
R = at( assert( wax.kind.ast 'boolean' ) )
: isTable (0)
: key 't' : eq 'boolean' : back()
: key 'v' : eq (nil)

-- {t='function'}
R = at( assert( wax.kind.ast 'function' ) )
: isTable (0)
: key 't' : eq 'function' : back()
: key 'v' : eq (nil)

-- {t='number'}
R = at( assert( wax.kind.ast 'number' ) )
: isTable (0)
: key 't' : eq 'number' : back()
: key 'v' : eq (nil)

-- {t='table'}
R = at( assert( wax.kind.ast 'table' ) )
: isTable (0)
: key 't' : eq 'table' : back()
: key 'v' : eq (nil)

-- {t='string'}
R = at( assert( wax.kind.ast 'string' ) )
: isTable (0)
: key 't' : eq 'string' : back()
: key 'v' : eq (nil)

-- {t='thread'}
R = at( assert( wax.kind.ast 'thread' ) )
: isTable (0)
: key 't' : eq 'thread' : back()
: key 'v' : eq (nil)

-- {t='userdata'}
R = at( assert( wax.kind.ast 'userdata' ) )
: isTable (0)
: key 't' : eq 'userdata' : back()
: key 'v' : eq (nil)
end


-- Equals
do
-- {t='eq', v='""'}
R = at( assert( wax.kind.ast '""' ) )
: isTable (0)
: key 't' : eq 'eq' : back()
: key 'v' : eq ''

-- {t='eq', v=true}
R = at( assert( wax.kind.ast 'true' ) )
: isTable (0)
: key 't' : eq 'eq' : back()
: key 'v' : eq (true)

-- {t='eq', v=false}
R = at( assert( wax.kind.ast 'false' ) )
: isTable (0)
: key 't' : eq 'eq' : back()
: key 'v' : eq (false)

-- {t='eq', v='moon'}
R = at( assert( wax.kind.ast '"moon"' ) )
: isTable (0)
: key't' : eq'eq' : back()
: key'v' : eq'moon'

-- {t='eq', v='true'}
R = at( assert( wax.kind.ast '"true"' ) )
: isTable (0)
: key't' : eq'eq' : back()
: key'v' : eq'true'

-- {t='eq', v='table'}
R = at( assert( wax.kind.ast '"table"' ) )
: isTable (0,2)
: key 't' : eq 'eq' : back()
: key 'v' : eq 'table'

-- {t='eq', v=10}
R = at( assert( assert( wax.kind.ast '10' ) ) )
: type'table'
: key 't' : eq 'eq' : back ()
: key 'v' : eq (10) : back ()

-- {t='eq', v='@ Asteróides'}
R = at( assert( assert( wax.kind.ast '"@ Asteróides"' ) ) )
: isTable (0)
: key 't' : eq 'eq' : back()
: key 'v' : eq '@ Asteróides'
end

-- Enum
do
R = at( assert(wax.kind.ast '"a" | 1 | true') )
: isTable (0, 2)
: key 't' : eq 'enum' : back()
: key 'v' : isTable (3,3)
  : key(1) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'a'  : back()
    : back()
  : key(2) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (1) : back()
    : back()
  : key(3) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (true) : back()
    : back()

R = at( assert(wax.kind.ast 'true | 1 | "c"') )
: isTable (0, 2)
: key 't' : eq 'enum' : back()
: key 'v' : isTable (3,3)
  : key(3) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'c'  : back()
    : back()
  : key(2) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (1) : back()
    : back()
  : key(1) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (true) : back()
    : back()
end

-- List
do
R = at( assert( wax.kind.ast '{1,20,300,04}' ) )
: isTable (0,2)
: key 't' : eq 'table' : back()
: key 'v' : isTable (4,4)
  : key (1) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (1) : back()
    : back()
  : key (2) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (20) : back()
    : back()
  : key (3) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (300) : back()
    : back()
  : key (4) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (4) : back()
    : back()

R = at( assert( wax.kind.ast '{true, 10, "hi", false}' ) )
: isTable (0,2)
: key 't' : eq 'table' : back()
: key 'v' : isTable (4,4)
  : key (1) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (true) : back()
    : back()
  : key (2) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (10) : back()
    : back()
  : key (3) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'hi' : back()
    : back()
  : key (4) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (false) : back()
    : back()
end


-- Table
do

-- {t='table', v={[1]={t='eq',v='a'}, [2]={t='eq',v='b'}}}
R = at( assert( wax.kind.ast '{"a","b"}' ) )
: isTable (0)
: key 't' : eq 'table' : back()
: key 'v' : len(2)
  : key(1)
    : key 't' : eq 'eq' : back ()
    : key 'v' : eq 'a' : back ()
    : back ()
  : key(2)
    : key 't' : eq 'eq' : back ()
    : key 'v' : eq 'b' : back ()
    : back ()

-- {t='table', v={[{t='eq',v='planet'}] = {t='eq',v='Earth'}}}
R = at( assert( wax.kind.ast '{"planet" : "Earth"}' ) )
: isTable (0)
: key 't' : eq 'table' : back()
: key 'v' : type 'table'

  for left,right in pairs(R : node()) do
    at(left) : isTable (0)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'planet'
    at(right) : isTable (0)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'Earth'
  end

-- {t='table', v={[{t='eq',v='string'}]={t='eq',v=10}}}
R = at( assert( wax.kind.ast '{"string" : 10}' ) )
: isTable (0,2)
: key 't' : eq 'table' : back()
: key 'v' : isTable (0,1)

  for left,right in pairs(R : node()) do
    at(left) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'string'
        at(right) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (10)
  end

-- {t='table', v={[{t='eq',v=123}] = {t='eq',v=456} }}
R = at( assert( wax.kind.ast '{123 : 456}' ) )
: isTable (0,2)
: key 't' : type 'string' : eq 'table' : back()
: key 'v' : isTable (0,1)
  for key,val in pairs(R : node()) do
    assert(key.t == 'eq' and key.v == 123)
    assert(val.t == 'eq' and val.v == 456)
  end

-- {t='table', v={ { t='table', v={ [{t='eq',v=123}] = {t='eq',v=456} } } }}
R = at( assert( wax.kind.ast '{{123 : "hi"}}' ) )
: isTable (0,2)
: key 't' : eq 'table' : back()
: key 'v' : isTable (1,1)
  : key (1) : isTable (0,2)
    : key 't' : eq 'table' : back()
    : key 'v' : isTable (0,1)
    for K,V in pairs(R : node()) do
      K = at(K) : isTable (0,2)
        K : key 't' : type 'string' : eq 'eq' : back()
        K : key 'v' : eq (123)
      V = at(V) : type 'table'
        V : key 't' : eq 'eq' : back()
        V : key 'v' : eq 'hi'
    end

-- Mixed tables/lists
R = at( assert( wax.kind.ast '{{100,200},{true : false, "say" : "hello"},"hi"}' ) )
: isTable (0,2)
: key 't' : eq 'table' : back()
: key 'v' : isTable (3,3)
  : key(1) : isTable (0,2)
    : key 't' : eq 'table' : back()
    : key 'v' : isTable (2,2)
      : key(1) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq(100) : back()
        : back()
      : back()
    : back()
  : key(2) : isTable (0,2)
    : key 't' : eq 'table' : back()
    : key 'v' : isTable (0,2)
    for K,V in pairs(R:node()) do
      if K.v == true then
        K = at(K) : len(0,2)
          K : key 't' : eq 'eq' : back()
          K : key 'v' : eq(true)
        V = at(V) : len(0,2)
          V : key 't' : eq 'eq' : back()
          V : key 'v' : eq (false)
      else
        K = at(K) : len(0,2)
          K : key 't' : eq 'eq' : back()
          K : key 'v' : eq 'say'
        V = at(V) : len(0,2)
          V : key 't' : eq 'eq' : back()
          V : key 'v' : eq 'hello'
      end
    end

for _, sign in pairs{ '{{10,20},true:false}', '{true:false, {10,20}}' } do
  R = at (wax.kind.ast( sign ))
  : isTable (0,2)
    : key 't' : eq 'table' : back()
    : key 'v' : isTable (1,2)
      : key(1) : isTable (0,2)
        : key 't' : eq 'table' : back()
        : key 'v' : isTable (2,2)
          : key(1) : isTable (0,2)
            : key 't' : eq 'eq' : back()
            : key 'v' : eq (10) : back()
          : back()
          : key(2) : isTable (0,2)
            : key 't' : eq 'eq' : back()
            : key 'v' : eq (20) : back()
          : back()
        : back()
      : back()
      for K,V in pairs(R:node()) do
        if K ~= 1 then
          K = at(K) : isTable (0,2)
            K : key 't' : eq 'eq' : back()
            K : key 'v' : eq (true)
          V = at(V) : isTable (0,2)
            V : key 't' : eq 'eq' : back()
            V : key 'v' : eq (false)
        end
      end
end

-- Table + Enum
R = at( assert(wax.kind.ast '{"a"|"b","c"}') )
: isTable (0,2)
: key 't' : eq 'table' : back()
: key 'v' : isTable (2)
  : key (1) : isTable (0,2)
    : key 't' : eq 'enum' : back()
    : key 'v' : isTable (2,2)
      : key (1) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq 'a'  : back()
        : back()
      : key (2) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq 'b'  : back()
        :back()
      : back()
    : back()
  : key (2) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'c'  : back()
    :back()
  :back()

R = at( assert(wax.kind.ast '{"a", true|"c"}') )
: isTable (0,2)
: key 't' : eq 'table' : back()
: key 'v' : isTable (2,2)
  : key (1) : isTable (0,2)
    : key 't' : eq 'eq': back()
    : key 'v' : eq 'a' : back()
    : back()
  : key (2) : isTable (0,2)
    : key 't' : eq 'enum' : back()
    : key 'v' : isTable (2,2)
      : key (1) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq (true) : back()
        : back()
      : key (2) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq 'c' : back()
        : back()
      : back()
    : back()
  : back()

R = at( assert(wax.kind.ast '{"a"|"b":"c"|"d"}'))
R : isTable(0,2)
  : key 't' : eq 'table' : back()
  : key 'v' : isTable(0,1)
  for k,v in pairs(R:node()) do
    at(k) : isTable(0,2)
      : key 't' : eq 'enum' : back()
      : key 'v' : isTable(2,2)
        : key (1) : isTable(0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'a' : back()
          : back()
        : key (2) : isTable(0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'b' : back()
          : back()
        : back()
    at(v) : isTable(0,2)
      : key 't' : eq 'enum' : back()
      : key 'v' : isTable(2,2)
        : key (1) : isTable(0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'c' : back()
          : back()
        : key (2) : isTable(0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'd' : back()
          : back()
        : back()
  end
end


-- Function
do
R = at( assert( wax.kind.ast '("a","b") -> ("c",true)' ) )
: isTable (0,3)
: key 't' : eq 'func'
: back()
: key 'a' : isTable (2,2)
  : key(1) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'a' : back()
  : back()
  : key(2) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'b' : back()
  : back()
: back()
: key 'r' : isTable (2,2)
  : key(1) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'c' : back()
  : back()
  : key(2) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (true) : back()

-- Function with functions as arguments and returns
R = at( assert(wax.kind.ast '(("a")->("b"))->(("c")->("d"))'))
: isTable (0,3)
  : key 't' : eq 'func'    : back()
  : key 'a' : isTable(1,1)
    : key (1) : isTable(0,3)
      : key 't' : eq 'func' : back()
      : key 'a' : isTable(1,1)
        : key (1) : isTable(0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'a'  : back()
          : back()
        : back()
      : key 'r' : isTable(1,1)
        : key (1) : isTable(0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'b'  : back()
          : back()
        : back()
      : back()
    : back()
  : key 'r' : isTable(1,1)
    : key (1) : isTable(0,3)
      : key 't' : eq 'func' : back()
      : key 'a' : isTable(1,1)
        : key (1) : isTable(0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'c'  : back()
          : back()
        : back()
      : key 'r' : isTable(1,1)
        : key (1) : isTable(0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'd'  : back()
          : back()
        : back()
      : back()
    : back()

-- Function with enums as arguments and returns
R = at( assert(wax.kind.ast '("a"|"b", "c" ) -> ("d", "e"|"f")') )
: isTable (0,3)
  : key 't' : eq 'func' : back()
  : key 'a' : isTable  (2,2)
    : key (1) : isTable  (0,2)
      : key 't' : eq 'enum' : back()
      : key 'v' : isTable  (2,2)
        : key (1) : isTable  (0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'a' : back()
          : back()
        : key (2) : isTable  (0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'b' : back()
          : back()
        : back()
      : back()
    : key (2) : isTable  (0,2)
      : key 't' : eq 'eq' : back()
      : key 'v' : eq 'c'  : back()
      : back()
    : back()
  : key 'r' : isTable  (2,2)
    : key (1) : isTable  (0,2)
      : key 't' : eq 'eq' : back()
      : key 'v' : eq 'd' : back()
      : back()
    : key (2) : isTable  (0,2)
      : key 't' : eq 'enum'    : back()
      : key 'v' : isTable (2,2)
        : key (1) : isTable  (0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'e'  : back()
          : back()
        : key (2) : isTable  (0,2)
          : key 't' : eq 'eq' : back()
          : key 'v' : eq 'f'  : back()
          : back()
        : back()
      : back()
    : back()

-- { t='function',
--   a={
--     [1]= {
--       t = 'function',
--       a = { {t='eq',v=true}, {t='eq',v=10} },
--       r = { {t='eq',v=20} } },
--     [2]= {t='eq', v='b'}
--   },
--   r={
--     { t='function', a={ {t='eq', v='c'} }, r={ {t='eq', v=true} } }
--   },
-- }

R = at( assert( wax.kind.ast '((true,10) -> (20),"b") -> (("c")->(true), false)' ) )
: isTable (0,3)
: key 't' : eq 'func' : back()
: key 'a' : isTable (2,2)
  : key(1) : isTable (0,3)
    : key 't' : eq 'func' : back()
    : key 'a' : isTable (2,2)
      : key (1) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq (true) : back()
        : back()
      : key (2) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq (10) : back()
        : back()
      : back()
    : key 'r' : isTable (1,1)
      : key (1) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq (20) : back()
        : back()
      : back()
    : back()
  : key(2) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'b' : back()
    : back()
  : back()
: key 'r' : isTable (2,2)
  : key (1) : isTable (0,3)
    : key 't' : eq 'func' : back()
    : key 'a' : isTable (1,1)
      : key (1) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq 'c'  : back()
        : back ()
      : back()
    : key 'r' : isTable (1,1)
      : key (1) : isTable (0,2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq (true) : back()
        : back()
      : back()
    : back()
  : key (2) : isTable (0,2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (false) : back()
  : back()
: back()

end



--[[
wax.kind.match({
  'string',
  '"a"',
  "'a'",
}, 'a')
--]]
print('end ok')
