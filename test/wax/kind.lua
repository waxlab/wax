-- luacheck: ignore 311
local wax = require 'wax'
local at = wax.attest
local R

-- Primitives
do
-- {t='boolean'}
R = at( wax.kind.ast 'boolean' )
: type 'table' : ipairs (0)
: key 't' : eq 'boolean' : back()
: key 'v' : eq (nil)

-- {t='function'}
R = at( wax.kind.ast 'function' )
: type 'table' : ipairs (0)
: key 't' : eq 'function' : back()
: key 'v' : eq (nil)

-- {t='number'}
R = at( wax.kind.ast 'number' )
: type 'table' : ipairs (0)
: key 't' : eq 'number' : back()
: key 'v' : eq (nil)

-- {t='table'}
R = at( wax.kind.ast 'table' )
: type 'table' : ipairs (0)
: key 't' : eq 'table' : back()
: key 'v' : eq (nil)

-- {t='string'}
R = at( wax.kind.ast 'string' )
: type 'table' : ipairs (0)
: key 't' : eq 'string' : back()
: key 'v' : eq (nil)

-- {t='thread'}
R = at( wax.kind.ast 'thread' )
: type 'table' : ipairs (0)
: key 't' : eq 'thread' : back()
: key 'v' : eq (nil)

-- {t='userdata'}
R = at( wax.kind.ast 'userdata' )
: type 'table' : ipairs (0)
: key 't' : eq 'userdata' : back()
: key 'v' : eq (nil)
end

-- Equals
do
-- {t='eq', v=true}
R = at( wax.kind.ast 'true' )
: type 'table' : ipairs (0)
: key 't' : eq 'eq' : back()
: key 'v' : eq (true)

-- {t='eq', v=false}
R = at( wax.kind.ast 'false' )
: type 'table' : ipairs(0)
: key 't' : eq 'eq' : back()
: key 'v' : eq (false)

-- {t='eq', v='moon'}
R = at( wax.kind.ast '"moon"' )
: type 'table' : ipairs(0)
: key't' : eq'eq' : back()
: key'v' : eq'moon'

-- {t='eq', v='true'}
R = at( wax.kind.ast '"true"' )
: type'table' : ipairs(0)
: key't' : eq'eq' : back()
: key'v' : eq'true'

-- {t='eq', v='table'}
R = at( wax.kind.ast '"table"' )
: type'table' : ipairs(0) : pairs(2)
: key 't' : eq 'eq' : back()
: key 'v' : eq 'table'

-- {t='eq', v=10}
R = at( assert( wax.kind.ast '10' ) )
: type'table'
: key 't' : eq 'eq' : back ()
: key 'v' : eq (10) : back ()

-- {t='eq', v='@ Asteróides'}
R = at( assert( wax.kind.ast '"@ Asteróides"' ) )
: type 'table' : ipairs(0)
: key 't' : eq 'eq' : back()
: key 'v' : eq '@ Asteróides'
end


-- List
do
R = at( wax.kind.ast '{1,20,300,04}' )
: type 'table' : ipairs(0) : pairs(2)
: key 't' : eq 'table' : back()
: key 'v' : type 'table' : ipairs(4) : pairs(4)
  : key (1) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (1) : back()
    : back()
  : key (2) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (20) : back()
    : back()
  : key (3) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (300) : back()
    : back()
  : key (4) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (4) : back()
    : back()

R = at( wax.kind.ast '{true, 10, "hi", false}' )
: type 'table' : ipairs(0) : pairs(2)
: key 't' : eq 'table' : back()
: key 'v' : type 'table' : ipairs(4) : pairs(4)
  : key (1) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (true) : back()
    : back()
  : key (2) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (10) : back()
    : back()
  : key (3) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'hi' : back()
    : back()
  : key (4) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (false) : back()
    : back()
end


-- Table
do

-- {t='table', v={[1]={t='eq',v='a'}, [2]={t='eq',v='b'}}}
R = at( wax.kind.ast '{"a","b"}' )
: type 'table' : ipairs(0)
: key 't' : eq 'table' : back()
: key 'v' : ipairs(2)
  : key(1)
    : key 't' : eq 'eq' : back ()
    : key 'v' : eq 'a' : back ()
    : back ()
  : key(2)
    : key 't' : eq 'eq' : back ()
    : key 'v' : eq 'b' : back ()
    : back ()

-- {t='table', v={[{t='eq',v='planet'}] = {t='eq',v='Earth'}}}
R = at( wax.kind.ast '{"planet" : "Earth"}' )
: type 'table' : ipairs(0)
: key 't' : eq 'table' : back()
: key 'v' : type 'table'

  for left,right in pairs(R : node()) do
    at(left) : type 'table' : ipairs (0)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'planet'
    at(right) : type 'table' : ipairs (0)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'Earth'
  end

-- {t='table', v={[{t='eq',v='string'}]={t='eq',v=10}}}
R = at( wax.kind.ast '{"string" : 10}' )
: type 'table' : ipairs(0) : pairs(2)
: key 't' : eq 'table' : back()
: key 'v' : type 'table' : pairs(1)

  for left,right in pairs(R : node()) do
    at(left) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'string'
        at(right) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (10)
  end

-- {t='table', v={[{t='eq',v=123}] = {t='eq',v=456} }}
R = at( wax.kind.ast '{123 : 456}' )
: type 'table' : ipairs(0) : pairs(2)
: key 't' : type 'string' : eq 'table' : back()
: key 'v' : type 'table' : ipairs(0) : pairs(1)
  for key,val in pairs(R : node()) do
    assert(key.t == 'eq' and key.v == 123)
    assert(val.t == 'eq' and val.v == 456)
  end

-- {t='table', v={ { t='table', v={ [{t='eq',v=123}] = {t='eq',v=456} } } }}
R = at( wax.kind.ast '{{123 : "hi"}}' )
: type 'table' : ipairs(0) : pairs(2)
: key 't' : eq 'table' : back()
: key 'v' : type 'table' : ipairs(1) : pairs(1)
  : key (1) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'table' : back()
    : key 'v' : type 'table' : ipairs(0) : pairs(1)
    for K,V in pairs(R : node()) do
      K = at(K) : type 'table' : ipairs(0) : pairs(2)
        K : key 't' : type 'string' : eq 'eq' : back()
        K : key 'v' : eq (123)
      V = at(V) : type 'table'
        V : key 't' : eq 'eq' : back()
        V : key 'v' : eq 'hi'
    end

-- { t='table',
--   v = {
--     { t='table', v={ { t='eq', v=100 }, { t='eq', v=200 } } },
--     { t='table', v={
--       [{t='eq', v=true}] = { t='eq', v=false },
--       [{t='eq', v='say'}] = { t='eq', v='hello' }
--     } },
--     { t='eq', v='hi' }
--   }
-- }
R = at( wax.kind.ast '{{100,200},{true : false, "say" : "hello"},"hi"}' )
: type 'table' : ipairs(0) : pairs(2)
: key 't' : eq 'table' : back()
: key 'v' : type 'table' : ipairs(3) : pairs(3)
  : key(1) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'table' : back()
    : key 'v' : type 'table' : ipairs(2) : pairs(2)
      : key(1) : type 'table' : ipairs(0) : pairs(2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq(100) : back()
        : back()
      : back()
    : back()
  : key(2) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'table' : back()
    : key 'v' : type 'table' : ipairs(0) : pairs(2)
    for K,V in pairs(R:node()) do
      if K.v == true then
        K = at(K) : ipairs(0) : pairs(2)
          K : key 't' : eq 'eq' : back()
          K : key 'v' : eq(true)
        V = at(V) : ipairs(0) : pairs(2)
          V : key 't' : eq 'eq' : back()
          V : key 'v' : eq (false)
      else
        K = at(K) : ipairs(0) : pairs(2)
          K : key 't' : eq 'eq' : back()
          K : key 'v' : eq 'say'
        V = at(V) : ipairs(0) : pairs(2)
          V : key 't' : eq 'eq' : back()
          V : key 'v' : eq 'hello'
      end
    end

-- { t='table',
--   v = {
--     {t='table', v={
--       { t='eq', v=100 },
--       { t='eq', v=200 },
--     } },
--     [{t='eq', v=true}] = { t='eq',v=false }
--   }
-- }
for _, sign in pairs{ '{{10,20},true:false}', '{true:false, {10,20}}' } do
  R = at (wax.kind.ast( sign ))
  : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'table' : back()
    : key 'v' : type 'table' : ipairs(1) : pairs(2)
      : key(1) : type 'table' : ipairs(0) : pairs(2)
        : key 't' : eq 'table' : back()
        : key 'v' : type 'table' : ipairs(2) : pairs(2)
          : key(1) : type 'table' : ipairs(0) : pairs(2)
            : key 't' : eq 'eq' : back()
            : key 'v' : eq (10) : back()
          : back()
          : key(2) : type 'table' : ipairs(0) : pairs(2)
            : key 't' : eq 'eq' : back()
            : key 'v' : eq (20) : back()
          : back()
        : back()
      : back()
      for K,V in pairs(R:node()) do
        if K ~= 1 then
          K = at(K) : type 'table' : ipairs(0) : pairs(2)
            K : key 't' : eq 'eq' : back()
            K : key 'v' : eq (true)
          V = at(V) : type 'table' : ipairs(0) : pairs(2)
            V : key 't' : eq 'eq' : back()
            V : key 'v' : eq (false)
        end
      end
end

end


-- Function
do
-- { t='function',
--   a={ {t='eq', v='a'}, {t='eq', v='b'}, },
--   r={ {t='eq', v='c'}, {t='eq', v=true}, },
-- }
R = at( wax.kind.ast '("a","b") -> ("c",true)' )
: type 'table' :ipairs(0) :pairs(3)
: key 't' : eq 'function'
: back()
: key 'a' : type 'table' : ipairs(2) : pairs(2)
  : key(1) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'a' : back()
  : back()
  : key(2) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'b' : back()
  : back()
: back()
: key 'r' : type 'table' : ipairs(2) : pairs(2)
  : key(1) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'c' : back()
  : back()
  : key(2) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq (true) : back()

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

R = at( wax.kind.ast '((true,10) -> (20),"b") -> (("c")->(true), false)' )
: type 'table' : ipairs(0) : pairs(3)
: key 't' : eq 'function' : back()
: key 'a' : type 'table' : ipairs(2) : pairs(2)
  : key(1) : type 'table' : ipairs(0) : pairs(3)
    : key 't' : eq 'function' : back()
    : key 'a' : type 'table' : ipairs(2) : pairs(2)
      : key (1) : type 'table' : ipairs(0) : pairs(2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq (true) : back()
        : back()
      : key (2) : type 'table' : ipairs(0) : pairs(2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq (10) : back()
        : back()
      : back()
    : key 'r' : type 'table' : ipairs(1) : pairs(1)
      : key (1) : type 'table' : ipairs(0) : pairs(2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq (20) : back()
        : back()
      : back()
    : back()
  : key(2) : type 'table' : ipairs(0) : pairs(2)
    : key 't' : eq 'eq' : back()
    : key 'v' : eq 'b' : back()
    : back()
  : back()
: key 'r' : type 'table' : ipairs(2) : pairs(2)
  : key (1) : type 'table' : ipairs(0) : pairs (3)
    : key 't' : eq 'function' : back()
    : key 'a' : type 'table' : ipairs(1) : pairs(1)
      : key (1) : type 'table' : ipairs(0) : pairs(2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq 'c'  : back()
        : back ()
      : back()
    : key 'r' : type 'table' : ipairs(1) : pairs(1)
      : key (1) : type 'table' : ipairs(0) : pairs (2)
        : key 't' : eq 'eq' : back()
        : key 'v' : eq (true) : back()
        : back()
      : back()
    : back()
  : key (2) : type 'table' : ipairs(0) : pairs(2)
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
