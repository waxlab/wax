local wax = require 'wax'

local kind = {}
local ast = require 'wax.kind.ast'


local kcheck = {
  ['function'] = function(v)
    print 'herw'
  end
}





function kind.checkSingle(tgt, ann)
  local ok, total, msg = false, 0
  if type(ann) ~= 'string'
    then return nil, total, 'arg #1 must be table or string'
  end
  print(type(ann))
  local tree  = ast(ann)
  if type(tgt) == tree.t then
      ok, total, msg = kcheck[tree.t](tree)
  end
  print('...')
end
return kind
