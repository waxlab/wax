--[[
hello!
]]
local stars = {
  ['Altair' ] = 'Aquila',
  ['Regulus'] = 'Leo',
  ['Pollux' ] = 'Gemini',
  ['Spica'  ] = 'Virgo',
  ['Tupã'   ] = 'Crux',
}

for i,v in ipairs(data) do
  if stars[v] then
    --[[{{v}} is a star on {{stars[v]}}]]
  else
    --[[{{v}} was not found in data]]
  end
end
