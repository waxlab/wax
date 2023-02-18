--| # wax.sql
--| Simple SQLite3 driver for Lua.

--| ## Basic Usage
os.execute 'rm -rf /tmp/solarsystem.db'

do
--{
	local sql = require 'wax.sql'
	local db = sql.open '/tmp/solarsystem.db'

	assert(db:execute 'CREATE TABLE planets (name TEXT, moons INTEGER)')

	local stmt = db:prepare 'INSERT INTO planets (name, moons) VALUES (?, ?)'
	assert(1 == stmt:run("Mercury", 0))
	assert(1 == stmt:run("Venus",   0))
	assert(1 == stmt:run("Earth",   1))

	assert(1 == db:prepare('DELETE FROM planets WHERE name=?'):run('Mercury'))

	stmt = db:prepare 'SELECT name, moons FROM planets where moons > ?'

	local res = {}
	for row in stmt:fetch(0) do
		res[#res+1] = row
	end
	assert(res[1].name == 'Earth' and res[1].moons == 1)
	assert(#res == 1)

	stmt:finalize()
	db:close()
--}


--| ## Introduction
--|
--| `wax.sql` adds to the Wax Lua library the support to a database format
--| under the SQL specification using the Sqlite3 C library.
--|
--| It doest not intend to be a mere binding module to the SQLite3 library,
--| but a way to use SQLite3 adapted to Lua idioms. Also not all SQLite C Api
--| methods were implemented for the sake of simplicity and lightness.
--|
--| ###### Error handling
--|
--| Most of the functions returns a single value on success or two values
--| (nil and a string) on error. These errors occur mostly in case of database
--| conection or query error (wrong SQL syntax). In such cases you can test the
--| results to decide the proper handling on errors. In case of abort the
--| script execution, just wrap the function call in an `assert()`.
db = sql.open '/tmp/solarsystem.db'
--{
	local stmt, err = db:prepare [[ SOME INVALID QUERY ]]
	assert(not stmt and err) -- false handler and message of syntax error
--}
--|
--| When the error is about the Lua module misusage, a Lua error is thrown.
--| Examples of this behavior are an invalid number of SQL query parameters
--| (for mor or less), the usage of a closed handler or an invalid data type
--| passed to the statement.
--{
	local stmt, err = db:prepare [[ SELECT name,moons FROM planets where name=? ]]
	-- A nil passed to the query would throw a Lua error, so we use pcall
	local ok, res = pcall( stmt.run, stmt, nil )
	assert(not ok and type(res) == 'string')

	stmt:finalize()
--}
--| Usually these cases shouldn't occurr when the syntax and arguments are
--| correctly set.
--|
--| The only exception to these rules occurr on the statement `fetch()`
--| generator function. For more info read the `sql.fetchok()` function
--| reference.
--|
--| ###### SQLite query parameters
--|
--| As seen above, on _Basic Usage_, question marks `?` were used in the
--| statement. They are query parameters that allow to reuse the statement
--| prepared statement while giving a safe way to pass content to database.
--|
--| They can be of two kinds: named or anonymous.
--|
--| - `?` anonymous (or positional parameter) used to mark where a value will
--|   be bound. The first value passed to query will be the replacement
--|   to the first `?`, the second value to the second `?` and so on.
--{
	stmt = assert(db:prepare 'INSERT INTO planets (name, moons) VALUES (?, ?)')
	assert(stmt:run("Mars", 2) == 1)

	stmt:finalize()
--}
--|
--| - `?1`,`?2`...`?N` are positional parameters that allow repetions.
--|   The first value passed to the query will replace all the `?1` on the
--|   query, the second value to all `?2` and so on until the Nth value.
--{
	stmt = assert(db:prepare 'INSERT INTO planets (name, moons) VALUES (?1, ?2)')
	assert(stmt:run('Jupiter', 92) == 1)
	
	stmt:finalize()
--}
--|
--| - `@TTT`, `:TTT`, `$TTT` are named parameters. The `wax.sql` module
--|   ignores the first character (`@`, `:` and `$`) and consider the
--|   subsequent characters as the name. Parameters like `$moons`, `:moons` or
--|   `@moons` are replaced by the `moons` key of the argument table.
--{
	stmt = assert(db:prepare 'INSERT INTO planets (name, moons) VALUES (@name, @moons)')
	assert(stmt:run({name='Saturn', moons=83}) == 1)
	stmt:finalize()

	stmt = assert(db:prepare 'INSERT INTO planets (name, moons) VALUES (:name, :moons)')
	assert(stmt:run {name = "Uranus", moons = 27} == 1)
	assert(stmt:finalize())

	stmt = assert(db:prepare 'INSERT INTO planets (name, moons) VALUES ($name, $moons)')
	assert(stmt:run {name = "Neptune", moons = 14} == 1)
	assert(stmt:finalize())
--}
end



do
--| ## Reference
--|
--$ waxSql
--| It is an userdatum containing the connection handler of the opened database
--| and the following functions.
--|
--| - `waxSql:close()`
--| - `waxSql:execute()`
--| - `waxSql:prepare()`
--|
--| It is retrieved after a successfull database open with `sql.open()`
--|
--$ waxSqlStmt
--| It is the userdatum used to keep the prepared statement and contains the
--| following functions:
--|
--| - `waxSqlStmt:fetch()`
--| - `waxSqlStmt:finalize()`
--| - `waxSqlStmt:run()`
--|
--| A new instance of `waxSqlStmt` is obtained for every successfull call to
--| `waxSql:prepare()`
--|
--$ sql.null
--|
--| A special type to represent the SQLite `NULL` value on Lua side.
--| When a SQLite row contains a value `NULL` it will arrive on Lua side as
--| `sql.null`. It can also be passed as argument for `waxSqlStmt:run()` and
--| `waxSqlStmt:fetch()` to bind the SQLite NULL value on prepared statements.
--|
--{
	local sql = require 'wax.sql'
	local db   = sql.open('/tmp/solarsystem.db')

	-- Don't be confuse, wsql.null is not nil
	assert(type(sql.null) ~= nil)
	assert(type(sql.null) == 'userdata')

	-- The proper way to add nil values
	local stmt = db:prepare 'INSERT INTO planets (name, moons) VALUES (?,?)'
	assert(1 == stmt:run('Ceres', sql.null))
	assert(1 == stmt:run('Varuna',sql.null))

	-- The retrieved data is comparable with wax.sql.null type
	stmt = assert(db:prepare 'SELECT name, moons FROM planets WHERE moons IS NULL')
	local iter = stmt:fetch()
	
	local r1, r2 = iter(), iter()
	assert(r1.name == "Ceres"  and r1.moons == sql.null)
	assert(r2.name == "Varuna" and r2.moons == sql.null)
	assert(not iter())

	stmt:finalize()
--}



--$ sql.open(filename:string) : waxSql | nil, string, number
--| Open the database file, creating it if not exists
--|
--| A successful example:
--{
	local db, err = sql.open '/tmp/solarsystem.db'

	assert(db)
	assert(err == nil)
--}
assert(db:close())

--| A failing attempt looks like:
--{
	local db, err = sql.open('/donotexist/x.db')
	assert(db == nil)
	assert(err == 'unable to open database file')
--}



--$ sql.close(db: waxSql) : boolean
--$ waxSql:close() : boolean
--| Closes the database handler, returning true if it was opened
--| or false if it was already closed.
--{
	local db = assert( sql.open '/tmp/solarsystem.db' )
	assert(db:close() == true)  -- true when db was opened
	assert(db:close() == false) -- false when already closed
--}



--$ sql.execute(db: waxSql, sql: string [, result: table]) : true | nil, string
--$ (waxSql):execute(sql: string) : true | nil, string
--| Executes single or multiple queries.
--|
--| This function is intended for bulk query execution or queries that doesn't
--| receives parameters or doesn't need to fetch data.
--|
--| If you need pass external data to database, i.e., add, replace, delete or
--| query values using values that come from user/external input, you are
--| encouraged to prefer the `sql.run()` and `sql.fetch()` functions using
--| named parameters to avoid SQL injection.
--{
	local sql = require 'wax.sql'
	local db, res, err

	db = sql.open('/tmp/solarsystem.db')

	-- Success example
	res, err = db:execute [[
		CREATE TABLE IF NOT EXISTS "planets" ( "name" TEXT, "moons" INTEGER )
	]]
	assert(res == true and not err)

	-- Error, because table already exists
	res, err = db:execute [[
		CREATE TABLE "planets" ("name" TEXT, "moons" INTEGER)
	]]
	assert(not res and err)

	-- Example containing multiple statements
	res, err = db:execute [[
		CREATE TABLE asteroids (name TEXT, size INTEGER);
		CREATE TABLE IF NOT EXISTS planets (name TEXT, moons INTEGER);
	]]
	assert(res and not err)

	-- Example containing error on third statement:
	res, err = db:execute [[
		DROP TABLE asteroids;
		CREATE TABLE IF NOT EXISTS planets (name TEXT, moons INTEGER);
		CREATE BLABLA
	]]
	assert(not res)
	assert(err:match('#%d') == '#3')

	db:close()
--}



--$ sql.prepare(db: waxSql, sql: string) : waxSqlStmt | nil, string
--$ (waxSql):prep(sql: string) : boolean

--| Prepares a new statement to be used to query the database.
--| The statement preparation instructs sqlite about the structure of the
--| query.
--|
--| This function returns the `waxSqlite3Stmt` userdata or nil and a descriptive
--| error message.
--{
	local db, stmt, res, err
	db = assert( sql.open('/tmp/solarsystem.db') )

	stmt, err = db:prepare [[
		SELECT name
		FROM planets
		WHERE moons > 1
			AND moons < 50
	]]
	assert(stmt and err == nil)
	stmt:finalize()

	-- Error example
	stmt, err = db:prepare [[
		SELECT something
		FROM   a_table_that_not_exists
	]]
	assert(stmt == nil and err)
--}
assert(type(sql.prepare) == 'function' and type(db.prepare) == 'function')



--$ sql.run(stmt: waxSqlStmt, ...) : integer | nil, string
--$ (waxSqlStmt):run(...) : integer | nil, string
--| Execute the statement replacing the placeholders by its arguments.
--|
--| When calling over a statement with anonymous parameters, the variadic part
--| of the function can receive any `number`, `string` or `waxSqlite.NULL`
--| types as argument. The amount of arguments should coincide with the
--| prepared statement parameters, otherwise the function throws an error.
--|
--| When calling over a statement with named parameters, the variadic part
--| should receive a single table, where each key correspont to a named
--| parameter of the statement.
--|
--| In case of success the function returns the number of rows changed.
--| Otherwise it returns `nil` and a descriptive error message.
--|
--{
	local stmt = db:prepare 'INSERT INTO planets (name, moons) VALUES (?, ?)'
	local affected, err = stmt:run('Mercury',  0)

	assert(affected == 1)
	assert(not err)
	
	stmt:finalize()

	-- In below example 2 rows are deleted:
	stmt = db:prepare [[ DELETE FROM planets WHERE moons < ? ]]
	affected, err = stmt:run(1)

	assert(affected == 2)
	assert(not err)
	
	stmt:finalize();
--}
assert(type(sql.run) == 'function' and type(stmt.run) == 'function')



--$ sql.fetch(stmt: waxSqlStmt, ...) : iterator() : table | nil
--$ waxSqlStmt:fetch(...) : iterator() : table | nil
--| Apply values to a statement, run the query and returns an iterator
--| function. The iterator fetches a Sqlite row in each call or nil at
--| an error or at the end.
--{
	local stmt = assert(db:prepare [[ SELECT * FROM planets ]])
	local res = {}
	
	for row in stmt:fetch() do
		res[row.name] = row.moons
	end
	
	assert(res.Earth == 1)
	assert(res.Mars == 2)

	stmt:finalize()
--}
assert(type(sql.fetch) == 'function' and type(stmt.fetch) == 'function')



--$ sql.fetchok(stmt: waxSqlStmt): true | nil, string
--$ waxSqlStmt:fetchok(stmt: waxSqlStmt): true | nil, string
--| Check if the last `fetch()` occurred without any error.
--|
--{
	local ok, msg
	local stmt = assert(db:prepare('SELECT count(*) as n FROM planets LIMIT 1'))

	local res = {}
	for row in stmt:fetch() do
		res[#res+1]=row.n
	end
	assert(stmt:fetchok())
--}
--| The `fetch()` function generates an iterator function. Due to its nature,
--| it function returns `nil` when there are not more rows to be fetched, what
--| can hide some SQLite internal error. Throw an error would demand more
--| control from the user, what is not always desirable.
--|
--| When a statement is prepared with `sql.prepare()` this function returns
--| `nil, "unfetched"`. If no error ocurred but still are results to be
--| fetched, this function returns `nil, "pending"`. After all the data is
--| fetched it just returns `true`. In case of an internal error like
--| out of space in disk, permission or out of memory (and others), the return
--| is `nil` plus an descriptive error string.
--{
	local stmt = assert(db:prepare('SELECT count(*) as n FROM planets LIMIT 1'))

	-- before run the generator function `sql.fetch()`
	ok, msg = stmt:fetchok()
	assert(ok == true and msg == nil)

	-- after run the generator, but before run first iteration
	local iter = stmt:fetch()
	ok, msg = stmt:fetchok()
	assert(not ok and msg == "unstarted")

	-- after run iteration 1 of 1
	iter()
	ok, msg = stmt:fetchok()
	assert(not ok and msg == "pending")

	-- after run iteration 2 of 1 (to retrieve the nil)
	iter()
	ok, msg = stmt:fetchok()
	assert(ok and not msg) -- Fetched all, so ok.

	-- we call `sql.fetch()` again on same query.
	-- then finalize the prepared statement to make it unusable.
	iter = stmt:fetch()
	stmt:finalize()
	ok, msg = stmt:fetchok()

	-- observe that `sql.fetchok()` returns the error message
	-- and even trying to use a previous generated iterator
	-- nothing is retrieved.
	assert(not ok and type(msg) == 'string')
	assert(iter() == nil)
--}

--$ sql.version() : string, string
--| Returns the version of internally used libsqlite3 and its source code id used.
--{
	local ver, id = sql.version()
	assert(type(ver) == 'string')
	assert(type(id)  == 'string')
--}
end

--vim: foldmethod=marker foldmarker=--{,--}
