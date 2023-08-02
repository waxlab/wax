--[[

Ordered Associative Arrays
--------------------------

This is a data structure divided in a string keyed record part and a list
pointing to the keys.

With table notation:

- you can add new keys but not change an existing one.
- you cannot remove record entries
- numerical indexes are used only to access values
- negative numerical indexes can be used to access the record key position from
  the end.

With specialized functions:

- you can create, read, update or delete entries from the record.
- you can reorder using the ``orecord.sort()`` mixing ``orecord.remove()`` and
  ``orecord.insert()``.


* A new string key can be inserted using table notation but cannot be changed
directly this way.
* A the keys can be accessed using table

--]]

local oas = require 'wax.ordassoc'
local x = oas.new()
--x(10,2)  -- error key cannot be number
x('a',1) -- ok
x('a',2) -- error duplicate
x('a',nil) -- error needs value
print(x['a']) -- get the value
print(x[1])   -- get the first key
oas.remove(x, 'a') -- remove record for a key
oas.remove(x, 1 ) -- remove 1st record
oas.insert(x, 'a', 3, 1) --insert record a, with value 3 at pos 1
