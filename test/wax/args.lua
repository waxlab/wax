-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--| # wax.args
--| Parse command line arguments.
--|
--| Different from the C `getopt()` or the GNU convention, `wax.args`
--| looks for a simpler way of handling command line arguments.
--|
--| **The result table**
--|
--| The return of the parsing function is a table. Consider the below
--| example where the R is the resulting table of a parse:
--|
--| ```
--|   myaibot  --star  --maxmag 9 --cnt vir --cnt leo 1982 09 21 00 15
--|            |_____| |________| |_______| |_______| |______________|
--|               |         |        |          |             |
--| R.opt.star = { }        |        |----------'             |
--| R.opt.maxmag = { "9" } -'        |                        |
--| R.opt.cnt = { "vir", "leo" } ----'                        |
--| R.arg = { "1982","09","21","00","15" } -------------------'
--| ```
--|
--| 1. Every leading `--` string is parsed as an option and stored without the
--|    `--` prefix as a key on result table.
--| 2. The first value after an option is evaluated as the value of the option.
--| 3. The same option can be found with different values, as the result table
--|    store the option values as a list.
--| 4. Dangling options (options with no value) are simply stored as an empty
--|    table.
--| 5. After a presence of a no-option or the `--` string, every further
--|    string is evaluated as an argument.
--|
--| Basic usage:
--{
  local args = require 'wax.args'
  local res = args.parse()
--}





--$ args.parse( [arg: list [, index: number] ] ): table
--| Parses the argument list and returns a table as in "result table"
--| described above.
--|
--| It parses tha Lua `arg` variable by default, unless you inform a list
--| as its first argument. When explicitly informing the list of arguments
--| you can also inform the index of the list from where the parse
--| should start.
--{
do
  local was = require "wax.was"
  local args = require "wax.args"

  local arg1, arg2, res

  -- emulates what you would receive in the standard Lua arg global var
  arg1 = {'--op1','v1','--op2','v2a','--op3','--op2','v2b','a1','a2'}
  arg2 = {'subcmd','--op1','v1','--op2','v2a','--op3','--op2','v2b','a1','a2'}
  res = {
    opt = { op1 = {'v1'}, op2 = {'v2a','v2b'}, op3 = {} },
    arg = { 'a1','a2' }
  }

  assert(was.similar( args.parse(arg1), res ))
  assert(was.similar( args.parse(arg2,2), res ))

  -- after the first non option assumes the remaining are all arguments
  arg1 = {'somevalue','--opt1','--opt2','val2','a1','a2'}
  arg2 = {'subcmd','somevalue','--opt1','--opt2','val2','a1','a2'}
  res = {
    opt = {},
    arg = {'somevalue','--opt1','--opt2','val2','a1','a2'}
  }

  assert(was.similar( args.parse(arg1), res ))
  assert(was.similar( args.parse(arg2, 2), res ))
end
--}
