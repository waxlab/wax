local wax = require 'wax'
local sign

local
function show(res, sign)
  print '-------'
  print(sign)
  wax.show(res)
end


-- Primitives
do sign = 'boolean'  -- {t='boolean'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'boolean' and res.v == nil and #res == 0)
end
do sign = 'function' -- {t='function'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'function' and res.v == nil and #res == 0)
end
do sign = 'number'   -- {t='number'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'number' and res.v == nil and #res == 0)
end
do sign = 'table'    -- {t='table'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'table' and res.v == nil and #res == 0)
end
do sign = 'string'   -- {t='string'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'string' and res.v == nil and #res == 0)
end
do sign = 'thread'   -- {t='thread'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'thread' and res.v == nil and #res == 0)
end
do sign = 'userdata' -- {t='userdata'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'userdata' and res.v == nil and #res == 0)
end

-- Equals
do sign = '"moon"'  -- {t='eq', v='moon'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'eq' and res.v == 'moon' and #res == 0)
end
do sign = '"true"'  -- {t='eq', v='true'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'eq' and res.v == 'true' and #res == 0)
end
do sign = '"table"' -- {t='eq', v='table'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'eq' and res.v == 'table' and #res == 0)
end
do sign = 'true'    -- {t='eq', v=true}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'eq' and res.v == true and #res == 0)
end
do sign = 'false'   -- {t='eq', v=false}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'eq' and res.v == false and #res == 0)
end
do sign = '10'      -- {t='eq', v=10}
  local res = assert( wax.kind.ast(sign) )
  assert( type(res) == 'table' )
  assert( res.t == 'eq' and res.v == 10)
end
do sign = '"@ Asteróides"' -- {t='eq', v='@ Asteróides'}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'eq' and res.v == '@ Asteróides' and #res == 0)
end

-- Table
do sign='{"a","b"}' -- {t='table', v={[1]={t='eq',v='a'}, [2]={t='eq',v='b'}}}
  local res = assert( wax.kind.ast (sign) )
  assert(res.t == 'table' and type(res.v) == 'table' and #res.v == 2)
  assert(res.v[1].t == 'eq' and res.v[1].v == 'a')
  assert(res.v[2].t == 'eq' and res.v[2].v == 'b')
end
do sign='{"planet":"earth"}'
  -- {t='table', v={[{t='eq',v='planet'}] = {t='eq',v='earth'}}}
  local res = assert( wax.kind.ast (sign) )

  assert(type(res) == 'table')
  assert(type(res.v) == 'table')
  assert(res.t == 'table')
  for key,val in pairs(res.v) do
    assert(key.t == 'eq' and key.v == 'planet')
    assert(val.t == 'eq' and val.v == 'earth')
  end
end
do sign='{"string":10}'
  -- {t='table', v={[{t='eq',v='string'}]={t='eq',v=10}}}
  local res = assert( wax.kind.ast (sign) )

  assert(type(res) == 'table')
  assert(type(res.v) == 'table')
  assert(res.t == 'table')
  for key,val in pairs(res.v) do
    assert(key.t == 'eq' and key.v == 'string')
    assert(val.t == 'eq' and val.v == 10)
  end
end
do sign='{123:456}'          -- { [{t='eq',v=123}] = {t='eq',v=456} }
  local res = assert( wax.kind.ast (sign) )
  assert(type(res) == 'table')
  assert(type(res.v) == 'table')
  assert(res.t == 'table')
  for key,val in pairs(res.v) do
    assert(key.t == 'eq' and key.v == 123)
    assert(val.t == 'eq' and val.v == 456)
  end
end
do sign='{{123:"hi"}}'
  -- { t='table',
  --   v={
  --     [1] = {
  --       t='table',
  --       v={
  --         [{t='eq',v=123}] = {t='eq',v=456}
  --       }
  --     }
  --   }
  -- }
  local res = assert( wax.kind.ast (sign) )
  assert(type(res) == 'table' and res.t == 'table')
  assert(type(res.v) == 'table' and #res.v == 1)
  assert(type(res.v[1]) == 'table' and res.v[1].t == 'table')
  assert(type(res.v[1].v) == 'table')
  for key,val in pairs(res.v[1].v) do
    assert(key.t == 'eq' and key.v == 123)
    assert(val.t == 'eq' and val.v == 'hi')
  end
end
do sign='{{100,200},true:false}'
  -- { t='table',
  --   v = {
  --     [1] = {
  --       t = 'table'
  --       v = {
  --         [1] = { t = 'eq', v = 100 }
  --         [2] = { t = 'eq', v = 200 }
  --       }
  --     },
  --     [{t:'eq', v=true}] = {
  --       t:'eq',
  --       v:false
  --     }
  --   }
  -- }
  local res = assert( wax.kind.ast (sign) )
  assert(type(res) == 'table' and res.t == 'table')
  assert(type(res.v) == 'table' and #res.v == 1)
  assert(type(res.v[1]) == 'table' and res.v[1].t == 'table')
  assert(type(res.v[1].v) == 'table' and #res.v[1].v == 2)

  local items = 0
  wax.show(res)
  for _ in pairs(res.v) do 
    items = items+1
  end
  for key,val in pairs(res.v) do
    if key ~= 1 then
      assert(key.t == 'eq' and key.v == true)
      assert(val.t == 'eq' and val.v == false)
    end
  end
  assert(items == 2)
end
os.exit(0)


--sign = '{ "hi":"hello" }'
--res = wax.kind.ast {sign}
--assert(res[1][1].t == 'table' and res[1][1][1].hi == 'hello')




--show(res, sign)

--[[
wax.kind.match({
  'string',
  '"a"',
  "'a'",
}, 'a')
--]]
