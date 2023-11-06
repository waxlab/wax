--[[

Indexed Records
---------------

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

local irecord = require 'wax.irecord'
local x = irecord()

-- inner data representation

x.insert = 'Auriga' -- index 1 is 'insert', key 'insert' has 'Auriga' value
x.remove = 'Bootes' -- index 2 is 'remove', key 'remove' has 'Bootes' value
x.alpha  = 'Sirius'
x.beta   = 'Canopus'
assert(x:index(1) == 'insert' and x:index 'insert' == 'Auriga')
assert(x:index(2) == 'remove' and x:index 'remove' == 'Bootes')
assert(x:index(3) == 'alpha'  and x:index 'alpha'  == 'Sirius')
assert(x:index(4) == 'beta'   and x:index 'beta'   == 'Canopus')

x:remove('insert')
assert(x:index 'insert' == nil) -- key was removed
assert(x:index(1) == 'remove' ) -- index rearranged
assert(x:len() == 3)            -- list resized

x:remove(1)
assert(x:index 'remove' == nil) -- removed by position
assert(x:index(1) == 'alpha')

x:insert('gama', 'Alpha Centauri')
assert(x:index(3) == 'gama' and x:index(4) == nil and x:len() == 3)
assert(x:index 'gama' == 'Alpha Centauri')


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

assert(x:concat(',') == 'alpha,beta,gama')

local data = x:unwrap()
assert(#data == 3)
assert(data[1] == 'alpha' and data.alpha == 'Sirius')
assert(data[2] == 'beta'  and data.beta  == 'Canopus')
assert(data[3] == 'gama'  and data.gama  == 'Alpha Centauri')

