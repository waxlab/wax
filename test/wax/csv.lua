--| # wax.csv
--| CSV reader. Reads CSV data in the Lua lists format or as records using
--| iterators.
--|
--| CSV is not a very well standardized file format. Each software implement
--| its own way of write to CSV files, and while there is RFC 4180 it is still
--| implemented in many different ways depending on the software.
--|
--| This module tries to address the RFC 4180 specification while being
--| sufficient flexile to be used in with different separators and quoting
--| characters, and still with no quoting, acting like a TSV file format.
--|

--| ## Basic Usage
--|
--| ### Writing CSV files
--|
--| This modulemodule doesn't provide a way to write new CSV files. Write such
--| would add overcomplexity to the module while Lua already is simple and
--| sufficient to make it easy:
--{
	local file = os.tmpname()
	local fh = io.open(file,'w')

	local header = '%q,%q,%q,%q,%q\n'
	local record = '%q,%s,%s,%s,%s\n'

	fh:write (header:format('Planet','Moons','Mass','Aphelion','Perihelion') )
	fh:write (record:format('Earth', 1, 1.0, 1.01, 0.98))
	fh:write (record:format('Mars',  2, 0.1, 1.66, 1.38))
	fh:write (record:format('Venus', 0, 0.8, 0.72, 0.72))
	fh:close()
--}
--| ### Handling CSV files.
--|
--| The usage flow of CSV files with `wax.csv` consists in:
--|
--| - Open the file, optionally specifying the delimiter and quoting char used;
--| - Read the content through iterators, choosing between read the rows as a
--|   list or as a record;
--| - Close the handler.
do
--{
	-- Opening the file. Default is `,` as separator and `"` as quoting.
	local csv = require 'wax.csv'
	local handler = csv.open(file)

	-- Reads each row of CSV as a list (indexed values)
	local lists = {}

	for list in handler:lists() do
		lists[#lists+1] = list
	end

	assert(lists[1][1] == 'Planet' and lists[1][5] == 'Perihelion')
	assert(lists[2][1] == 'Earth'  and lists[2][4] == '1.01')
	assert(lists[4][1] == 'Venus'  and lists[4][3] == '0.8')

	-- Reads each row of CSV as a record (key/value tables)
	-- using the first record row as the keys
	local records = {}

	for rec in handler:records() do
		records[#records+1] = rec
	end

	assert(records[1].Planet == 'Earth')
	assert(records[2].Planet == 'Mars')
	assert(records[3].Planet == 'Venus')

	assert(records[1].Perihelion == '0.98')
	assert(records[2].Perihelion == '1.38')
	assert(records[3].Perihelion == '0.72')

	-- Reads each row of CSV as a record, but we specify which will be
	-- the keys of resulting record.
	local res = {}
	local headers = {
		'body','sat','weight','max dist','min dist'
	}

	for rec in handler:records(headers) do
		res[#res+1] = rec
	end

	assert(res[1].body == 'Planet')
	assert(res[2].body == 'Earth')
	assert(res[1]['min dist'] == 'Perihelion')
	assert(res[2]['min dist'] == '0.98')

	-- Finally we close the handler.
	assert(handler:close() == true)

	-- But it will give no error trying to close again
	assert(handler:close() == false)
--}
end

--|
--| ### Reading a TSV file
--|
--| TSV (tab separated values) is like a CSV, except that it strictily uses
--| tabs as field delimiter and has no quoting.
--|
--| The `wax.csv` module can read TSV files using `\t` as separator and `\0`
--| as quoting.
--|
--| Example:
do
--{
	-- We create the example file
	local file = os.tmpname()
	local fh = io.open(file,'w')
	local record = '%s\t%s\t%s\n'

	fh:write( record:format('Planet','Moons','Nickname') )
	fh:write( record:format('Earth', 1, '"Blue Marble"') )
	fh:write( record:format('Mars',  2, '"Morning Star"') )
	fh:write( record:format('Venus', 0, '"Red Planet"') )
	fh:close()

	-- Now we retrieve the data from the example file
	local csv = require 'wax.csv'
	local handler = csv.open(file, '\t','\0')
	local res = {}
	for rec in handler:records() do
		res[#res+1] = rec
	end

	assert(res[1].Planet   == 'Earth')
	assert(res[2].Moons    == '2')
	assert(res[3].Nickname == '"Red Planet"') -- preserved quotes

	-- Clean the house...
	assert(handler:close())
	os.remove(file)
--}
end

--| ## Module Reference

--$ wax.csv.open(file [,sep, quo:string]) : waxCsv | (nil, string)
--| Open a CSV file and returns its handler.
--|
--| There are two optional parameters:
--| * `sep` indicates the separator to be used (default `,`)
--| * `quo` indicates the quoting character to be used (default `"`)
--|
--| Once you call this function all subsequent functions on the handler will
--| respect the choosen separator `sep` and quoting `quo`.
--|
--| This function returns `waxCsv` userdata on success, or `nil` and a
--| descriptive message on error.
--| See `wax.csv.lists()`, `wax.csv.records()` for examples.


--$ wax.csv.lists( waxCsv ) : iterator()
--$ waxCsv:lists() : iterator()
--| Returns an iterator that retrieves each csv line as a list of values.
--|
--| Each time you call this function in an opened waxCsv the file is
--| reopened and position set at its beginning.
--|
--| It provides a flexible way to get values when CSV has different number of
--| values in each line.
--|

-- SPEC TEST 1: delimiter positions, quoting positions
do
	local csv = require 'wax.csv'
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

	local csvh = csv.open(file)
	local res = {}
	for list in csvh:lists() do
		assert(#list > 0)
		res[#res+1] = list
	end
	assert(csvh:close() == true)

	os.remove(file)

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
	assert(res[2][1] == ''    )
	assert(res[2][2] == ' b2' )
	assert(res[2][3] == ' b"3')
	assert(res[2][4] == 'b"4"')
	assert(res[2][5] == 'b5 ' )

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

-- SPEC TEST 2: different delimiter and quote
do
	local csv = require 'wax.csv'
	local file = os.tmpname()
	local fh = io.open(file, 'w')
	fh:write( table.concat({
		--[[ R1 ]] '%a 1%|eeeee|%a| 3%|% a\n4%|%a%%5%',
		--[[ R2 ]] '| b2| b%3|b%4%|b5 ',
		--[[ R3 ]] '||||',
		--[[ R4 ]] '%%|%%|%%|%%|%%|%%',
		--[[ R5 ]] '%f\n1%|%\r\n%|%%%%',
	},"\r\n").."\r\n" )
	fh:close()

	local csvh = csv.open(file,'|','%')
	local res = {}
	for list in csvh:lists() do
		assert(#list > 0)
		res[#res+1] = list
	end
	assert(csvh:close() == true)

	os.remove(file)

	assert(#res == 5, 'number of records')

	-- R1, R2:
	-- * quoted and simple values,
	-- * edge whitespaces
	-- * values with line breaks
	assert(#res[1] == 5)
	assert(res[1][1] == 'a 1'  )
	assert(res[1][2] == 'eeeee')
	assert(res[1][3] == 'a| 3' )
	assert(res[1][4] == ' a\n4')
	assert(res[1][5] == 'a%5'  )

	assert(#res[2] == 5)
	assert(res[2][1] == ''    )
	assert(res[2][2] == ' b2' )
	assert(res[2][3] == ' b%3')
	assert(res[2][4] == 'b%4%')
	assert(res[2][5] == 'b5 ' )

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
	assert(res[5][3] == '%')
end




--$ wax.csv.records(waxCsv [, head: list]) : iterator()
--$ waxCsv:records([head: list]) : iterator()
--|
--| Returns an iterator function to retrieve csv records as Lua key/value tables
--|
--| The first CSV record is used by default as field names when using this
--| function and so it is not retrieved by the iterator as a result record.
--|
--| When the optional `head` list of strings is specified, then its values are
--| used as field names and the first CSV record is retrieved as result record
--| like any subsequent record.
--|
--| When a value or header is not found to its counterpart then the value is
--| not added to the retrieved record table.
--|
--| Like `wax.csv.lists` each time this function is called against waxCsv,
--| this userdata will be reset and the file reopened.

--$ wax.csv.close( waxCsv )
--$ waxCsv:close() : boolean
--| Close a opened `waxCsv` and returns true.
--| If the `waxCsv` is already closed, returns false.
do
--{
	local csv = require 'wax.csv'
	local handler = csv.open(file)
	assert(handler:close() == true)
	assert(handler:close() == false)
--}
end


-- Separator tests
