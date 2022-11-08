local fs  = require 'wax.fs'


--$ wax.csv.open(file, mode: string [, sep: string, quo: string]) : csvdata | ( nil, string )
--| Open a CSV file and returns its handler.
--|
--| `mode` should be one of:
--| * `r` Open file to be read
--| * `w` Open file to be written
--|
--| There are two optional parameters:
--| * `sep` indicates the separator to be used (default `,`)
--| * `quo` indicates the quoting character to be used (default `"`)
--|
--| This function returns `csvdata` userdata on success, or `nil` and a message
--| on error. See `wax.csv.irecords()`, `wax.csv.records()` and
--| `wax.csv.write()` for examples.


--$ wax.csv.irecords( csvdata ) : iterator()
--$ csvdata:irecords() : iterator()
--| Return iterator function to retrieve csv records as Lua index/value tables
--| (tables indexed by number position of csv columns)
--|
do
  local csv = require 'wax.csv'
  local file = os.tmpname()
  local fh = io.open(file, 'w')

  fh:write( table.concat({
    --[[ record 1 ]] '"a 1","","a, 3"," a\n4","a""5"',
    --[[ record 2 ]] ', b2, b"3,b"4",b5 ',
    --[[ record 3 ]] ',,,,',
    --[[ record 4 ]] '"","","","",""',
    --[[ record 5 ]] '"f\n1","\r\n","""",'
  },"\r\n").."\r\n" )
  fh:close()


  local csvh = csv.open(file,'r')
  local res = {}
  for row in csvh:irecords() do
    res[#res+1] = row
  end

  fs.unlink(file)
  assert(csvh:close() == true) -- if is open return true
  assert(not csvh:close())     -- return false if already closed

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
  os.exit(0);
end


--$ wax.csv.records(csvdata [, head: list]) : iterator()
--$ csvdata:records([head: list]) : iterator()
--| Return an iterator function retrieve csv records as Lua key/value tables.
--|
--| The first CSV record is used by default as field names when using this
--| function and so it is not retrieved by the iterator as a result record.
--|
--| When the optional `head` list of strings is specified, then its values are used as
--| field names and the first CSV record is retrieved as result record like
--| any subsequent record.
--| When a value or header is not found to its counterpart then the value is
--| not added to the retrieved record table.
do
  local csv = require 'wax.csv'
  local file = os.tmpname()
  local fh = io.open(file, 'w')
  fh:write( table.concat({
    ' a1,a2,"a 4","a\n4",a5 ',
    'b1,b2,"b3",b4',
    '"c1", "c2","c""3","c\n4"'
  }, "\r\n"))
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




