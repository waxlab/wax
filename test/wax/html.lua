-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--| # wax.html
--| HTML utilities.

local html = require 'wax.html'

--$ html.encode( text: string) : string
--| Encode html special symbols found in text to html entities
do
--{
  local decoded = [[ 1>0 & 'a'<"b" ]]
  local encoded = [[ 1&gt;0 &amp; &apos;a&apos;&lt;&quot;b&quot; ]]

  assert(html.encode(decoded) == encoded)
--}
end


--$ html.decode( html: string) : string
--| Decode html special symbols found in text to plain representation
do
--{
  local decoded = [[ 1>0 & 'a'<"b" ]]
  local encoded = [[ 1&gt;0 &amp; &apos;a&apos;&lt;&quot;b&quot; ]]

  assert(html.decode(encoded) == decoded)
--}
end
