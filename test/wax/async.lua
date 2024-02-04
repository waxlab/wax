local async = require 'wax.async'
local function teste()
  local x = 'teste'
  x = x..'oi';
  if x == 'ei' then
    print('kjkjkj')
  elseif x == 'oioio' then
    print('kjkjkjkkkk')
  else
    print('alguma coisa')
  end
  return 10 * 200, x;
end

local luaf = string.dump(teste)
local waxf = async.new(teste)

print('waxf',waxf)
