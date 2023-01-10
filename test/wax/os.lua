--| # wax.os
--| Operating system related library.
--|
--| This library contains functions related to specific OS actions that
--| are not related to user handling or filesystem.

local wax = require 'wax'
wax.os = require 'wax.os'

--$ wax.os.exec(command:string [, argv: string list]) : errorstr
--{ Replaces the current process by the `command`.
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
wax.os.exec('bash',{"-c", "ls -la /dev/null > /dev/null 2>&1"} )
os.exit(1) -- Will not trigger this error unless wax.os.exec has an error
--}
end
