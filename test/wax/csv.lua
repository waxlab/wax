local fs  = require 'wax.fs'
local csv = require 'wax.csv'


--$ wax.csv.open(file, mode: string]) : csvdata | nil, string
--| Open a CSV file and returns its handler.
--|
--| `mode` should be one of:
--| * `r` Open file to be read
--| * `w` Open file to be written
--|
--| It returns `csvdata` userdata on success, or `nil` and a message on error.
--| See `csvdata:irows()`, `csvdata:prows()` and `csvdata:write()` for examples.

--$ csvdata:irows()
--| Return an iterator resulting in a list (positive integer indexed table)
do
  local file = '/tmp/nada' -- os.tmpname()
  local handler = io.open(file, 'w')

  local csvdata = table.concat({
    --[[ record 1 ]] '"a 1","","a, 3"," a\n4","a""5"',
    --[[ record 2 ]] ', b2, b"3,b"4",b5 ',
    --[[ record 3 ]] ',,,,',
    --[[ record 4 ]] '"","","","",""',
    --[[ record 5 ]] '"f\n1","\r\n","""",'
  },"\r\n").."\r\n"
  handler:write (csvdata)
  handler:close()


  local fh = csv.open(file,'r')
  local res = {}
  for row in fh:irows() do
    res[#res+1] = row
  end

  -- Record 1 & 2 tests on:
  -- * quoted and simple values,
  -- * edge whitespaces
  -- * values with line breaks
  assert(res[1][1] == 'a 1'  )
  assert(res[1][2] == ''     )
  assert(res[1][3] == 'a, 3' )
  assert(res[1][4] == ' a\n4')
  assert(res[1][5] == 'a"5'  )

  assert(res[2][1] == ''     )
  assert(res[2][2] == ' b2'  )
  assert(res[2][3] == ' b"3' )
  assert(res[2][4] == 'b"4"' )
  assert(res[2][5] == 'b5 '  )

  -- Record 3: empty simple values
  assert(res[3][1] == '')
  assert(res[3][2] == '')
  assert(res[3][3] == '')
  assert(res[3][4] == '')
  assert(res[3][5] == '')

  -- Record 4: empty quoted values
  assert(res[4][1] == '')
  assert(res[4][2] == '')
  assert(res[4][3] == '')
  assert(res[4][4] == '')
  assert(res[4][5] == '')

  -- Record 5:
  assert(res[5][1] == 'f\n1')
  assert(res[5][2] == '\r\n')
  assert(res[5][3] == '"')
  assert(res[5][4] == '')   -- empty value after dangling separator
  assert(not res[6])        -- no empty record at the end

  fs.unlink(file)

  assert(fh:close() == true) -- if is open return true
  assert(not fh:close()) -- if is not open return nil

  os.exit(0);
end


--$ csvdata:prows([names: list]) : iterator() : table | nil
--| Return an iterator resulting in a string indexed table.
--| If the `names` list is provided, their values will be used as the record
--| keys. If not, the keys will be guessed from the first record.
do
  local fh = csv.open(file,'r')
  local n = 1
  for record in fh:records() do
    for k,v in pairs(record) do
      print(n, k, v)
    end
    n = n+1
  end
  fh:close()
end


--$ csvdata:write(values: list)
--| Writes a list into file respecting the separator. It not checks for the
--| amount of items on the list, so take care on nil values.
do
  local fh = csv.open(file,'w')
  for i,v in pairs(data) do
    fh:write(v)
  end
  fh:close()
end


--$ csvdata:close() : boolean
--| Try to close a not closed csvdata handler. It returns true on success or
--| false on an already closed handler




