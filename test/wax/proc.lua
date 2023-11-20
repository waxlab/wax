-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--| # wax.proc
--| Process management library.
--|
--| This library contains functions related to process management, like get or
--| set environment variables, fork and replace process.

local wax = require 'wax'

--$ wax.proc.setenv(name:string, value:string) : bool[, errorstr:string]
--| Sets environment variable `name` with the `value`.
--| It returns true in case of success or false and a error string otherwise
do

--{
  local setenv = wax.proc.setenv
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

--$ wax.proc.replace(command:string [, argv: string list]) : errorstr
--| Replaces the current process by the `command` using the Unix `exec`.
--|
--| When you call `wax.process.replace()` the current program will be replaced
--| by the `command` you specified (so you can't retrieve any return for this
--| function).
--|
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
  wax.proc.replace('bash', {"-c", ('[ "$$" == %q ]'):format(pid)})

  -- This block only run if the process couldn't be replaced
  print "Couldn't replace process"
  os.exit(1) -- Won't trigger error unless wax.process.replace had trouble.
--}
end


