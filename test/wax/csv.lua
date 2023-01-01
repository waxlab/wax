--| # wax.csv
--| CSV handlers. Writes Lua tables to CSV and reads CSV through
--| iterators.
local fs  = require 'wax.fs'


--$ wax.csv.open(file, mode:string [,sep, quo:string]) : CsvData | (nil, string)
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
--| on error. See `wax.csv.lists()`, `wax.csv.records()` and
--| `wax.csv.write()` for examples.


--$ wax.csv.lists( csvdata ) : iterator()
--$ csvdata:lists() : iterator()
--| Return an iterator that retrieves each csv line as a list of values.
--|
--| It provides a flexible way to get values when CSV has different number of
--| values in each line.

do
  local file = os.tmpname()
  local fh = io.open(file, 'w')
  fh:write( table.concat({
    --[[ R1 ]] '"a 1",eeeee,"a, 3"," a\n4","a""5"',
    --[[ R2 ]] ', b2, b"3,b"4",b5 ',
    --[[ R3 ]] ',,,,',
    --[[ R4 ]] '"","","","","",""',
    --[[ R5 ]] '"f\n1","\r\n",""""',
  },"\r\n").."\r\n" )
  fh:close()

--{
  local csv = require 'wax.csv'
  local csvh = csv.open(file,'r')
  local res = {}
  for list in csvh:lists() do
    assert(#list > 0)
    res[#res+1] = list
  end
--}

  fs.unlink(file)
  assert(csvh:close() == true) -- if it is opened
  assert(not csvh:close())     -- if already closed

  assert(#res == 5, 'number of records')

  -- R1, R2:
  -- * quoted and simple values,
  -- * edge whitespaces
  -- * values with line breaks
  assert(#res[1] == 5)
  assert(res[1][1] == 'a 1'  )
  assert(res[1][2] == 'eeeee')
  assert(res[1][3] == 'a, 3' )
  assert(res[1][4] == ' a\n4')
  assert(res[1][5] == 'a"5'  )

  assert(#res[2] == 5)
  assert(res[2][1] == ''     )
  assert(res[2][2] == ' b2'  )
  assert(res[2][3] == ' b"3' )
  assert(res[2][4] == 'b"4"' )
  assert(res[2][5] == 'b5 '  )

  -- R3: empty unquoted values
  assert(#res[3] == 5)
  assert(res[3][1] == '')
  assert(res[3][2] == '')
  assert(res[3][3] == '')
  assert(res[3][4] == '')
  assert(res[3][5] == '')

  -- R4: empty quoted values
  assert(#res[4] == 6)
  assert(res[4][1] == '')
  assert(res[4][2] == '')
  assert(res[4][3] == '')
  assert(res[4][4] == '')
  assert(res[4][5] == '')
  assert(res[4][6] == '')

  -- R5: quoted quotes and quoted breaks
  assert(#res[5] == 3)
  assert(res[5][1] == 'f\n1')
  assert(res[5][2] == '\r\n')
  assert(res[5][3] == '"')
end

----$ wax.csv.records(CsvData [, head: list]) : iterator()
----$ CsvData:records([head: list]) : iterator()
----|
----| Returns an iterator function retrieve csv records as Lua key/value tables.
----|
----| The first CSV record is used by default as field names when using this
----| function and so it is not retrieved by the iterator as a result record.
----|
----| When the optional `head` list of strings is specified, then its values are
----| used as field names and the first CSV record is retrieved as result record
----| like any subsequent record.
----|
----| When a value or header is not found to its counterpart then the value is
----| not added to the retrieved record table.
--do
--  local csv = require 'wax.csv'
--  local file = os.tmpname()
--  local fh = io.open(file, 'w')
--
--  fh:write( table.concat({
--    ' a1,a2,"a 4","a\n4",a5 ',
--    'b1,b2,"b3",b4',
--    '"c1", "c2","c""3","c\n4"'
--  }, "\r\n"))
--  fh:close()
--
--  local csvh = csv.open(file, "r")
--  local res = {}
--
--  print(csvh:records({
--    "ieoeoie",
--  }))
--
--  print("pppppp")
--  for k,v in csvh:records({"oio","eieie"}) do
--    print('K',k,'V',v)
--  end
--
--  print "oioioioioi"
--  os.exit(1)
--end
--
--
----$ CsvData:write(values: list)
----| Writes a list into file respecting the separator. It not checks for the
----| amount of items on the list, so take care on nil values.
--do
--  local fh = csv.open(file,'w')
--  for i,v in pairs(data) do
--    fh:write(v)
--  end
--  fh:close()
--end
--
--
----$ CsvData:close() : boolean
----| Try to close a not closed csvdata handler. It returns true on success or
----| false on an already closed handler




