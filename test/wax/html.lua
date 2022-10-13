--| # wax.html
--|
--| HTML handling module for Lua

local html = require 'wax.html'

--$ wax.html.encode( text: string) : string
--| Encode html special symbols found in text to html entities
do
--{
local decoded = [[ 1>0 & 'a'<"b" ]]
local encoded = [[ 1&gt;0 &amp; &apos;a&apos;&lt;&quot;b&quot; ]]

assert(html.encode(decoded) == encoded)
--}
end


--$ wax.html.decode( html: string) : string
--| Decode html special symbols found in text to plain representation
do
--{
local decoded = [[ 1>0 & 'a'<"b" ]]
local encoded = [[ 1&gt;0 &amp; &apos;a&apos;&lt;&quot;b&quot; ]]

assert(html.decode(encoded) == decoded)
--}
end
