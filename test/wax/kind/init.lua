local wax = require 'wax'
local kind = require 'wax.kind'

local function sum(a,b)
  return a+b
end

kind.checkSingle(string.format, '(number, number) -> (number)')
