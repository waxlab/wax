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

-- inner data representation
local data = x:unwrap()

x.insert = 'Auriga' -- index 1 is 'insert', key 'insert' has 'Auriga' value
x.remove = 'Bootes' -- index 2 is 'remove', key 'remove' has 'Bootes' value
x.alpha  = 'Sirius'
x.beta   = 'Canopus'
assert(data[1] == 'insert' and data.insert == 'Auriga')
assert(data[2] == 'remove' and data.remove == 'Bootes')
assert(data[3] == 'alpha'  and data.alpha  == 'Sirius')
assert(data[4] == 'beta'   and data.beta   == 'Canopus')

x:remove('insert')
assert(data.insert == nil)  -- key was removed
assert(data[1] == 'remove' and #data == 3) -- list was resized

x:insert('gama', 'Alpha Centauri')
assert(data[4] == 'gama')
assert(data.gama == 'Alpha Centauri')

x:remove('remove')


for i,v in x:ipairs() do
  assert(i and v)
  if i == 1 then assert(v == 'alpha') end
  if i == 2 then assert(v == 'beta') end
  if i == 3 then assert(v == 'gama') end
end

for k,v in x:pairs() do
  assert(k and v)
  if k == 'alpha' then assert(v == 'Sirius') end
  if k == 'beta'  then assert(v == 'Canopus') end
  if k == 'gama'  then assert(v == 'Alpha Centauri') end
end
