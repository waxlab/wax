--| # wax.arg - Argument parsing tools
--|
--| Different from the C `getopt()` or the GNU convention, `wax.getopt` looks
--| for a simpler way of handling command line arguments.
--|
--| ## The result table
--| The return of parsing functions is a table. Consider the below example
--| where the R is the resulting table of a parse:
--|
--| ```
--| myaibot  find --star --maxmag 9 --const vir --const leo 1982-09-21 00:00:15
--|          ╰─┬╯ ╰──┬─╯ ╰────┬───╯ ╰────┬────╯ ╰────┬────╯ ╰─────────┬───────╯
--|            │     │        │          │           │                │
--| P.cmd = "find"   │        │          ╰─────┬─────╯                │
--| P.opt.star = {} ─╯        │                │                      │
--| P.opt.maxmag = { "9" } ───╯                │                      │
--| P.opt.const = { "vir", "leo" } ────────────╯                      │
--| P.arg = { "1982-09-21", "00:00:15" } ─────────────────────────────╯
--| ```
--|
--| 1. Option names are prefixed with double hyphen-minus `--`:
--| 2. Option can have a value or just "be present". When an options doesn't
--| have a value it is evaluated to an empty table.
--| 3. The same option can occur multiple times. If it is followed by a value
--| it will be stored under a table.
--| 4. Processing stops after the presence of double hyphen `--` argument or
--| after an argument that doesn't fill an option value.
--|


--$ wax.arg.parse( [arg: list [, pos: number] ] ): table
--| parses the argument list and returns a table as in "result table" described
--| above.
--{
local wax = require "wax"
local argparse = require "wax.arg".parse

local arglist, result

arglist = {'--op1','v1','--op2','v2a','--op3','--op2','v2b','a1','a2'}
result = {
  opt = { op1 = {'v1'}, op2 = {'v2a','v2b'}, op3 = {} },
  arg = { 'a1','a2' }
}

assert(wax.similar( argparse(arglist), result ))

-- after the first non option assumes the remaining are all arguments
arglist = {'somevalue','--opt1','--opt2','val2','a1','a2'}
result = {
  opt = {},
  arg = {'somevalue','--opt1','--opt2','val2','a1','a2'}
}

assert(wax.similar( argparse(arglist), result))
--}
