-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--| # wax.os
--| Operating system related library.
--|
--| This library contains functions related to specific OS actions that
--| are not related to user handling or filesystem.

local wax = require 'wax'

--$ os.setenv(name:string, value:string) : bool[, errorstr:string]
--| Sets environment variable `name` with the `value`.
--| It returns true in case of success or false and a error string otherwise
do

--{
  local setenv = wax.os.setenv
  local envvar = "SomeVarName"
  setenv( envvar, "Testing Value" )
  assert(os.getenv(envvar) == "Testing Value")
  setenv( envvar, "Some Other Testing Value")
  assert(os.getenv(envvar) == "Some Other Testing Value")
--}
end


---------------------------------------------------------------
------ ATENTION: THIS SHOULD BE THE LAST TEST OF SCRIPT -------
---------------------------------------------------------------

--$ os.exec(command:string [, argv: string list]) : errorstr
--| Replaces the current process by the `command`.
--|
--| When you call `wax.os.exec()` the current program will be replaced by the
--| `command` you specified (so you cant retrieve any return of this function).
--| If the specified `command` cannot be started, the function returns a
--| descriptive error string.
--|
--| It is tested under the Lua REPL. Use it carefully as it can break the
--| host program when using Lua as a scripting extension.
do
--{
  local subproc = io.popen 'echo $PPID'
  local pid = subproc:read() -- Lua pid is the ppid of the child
  subproc:close()

  -- When process is replaced the pid's should be the same
  wax.os.exec('bash', {"-c", ('[ "$$" == %q ]'):format(pid)})

  -- This block only run if the process couldn't be replaced
  print "Couldn't replace process"
  os.exit(1) -- Will not trigger this error unless wax.os.exec has an error
--}
end


