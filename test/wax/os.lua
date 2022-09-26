--| ## wax.os
--| Operating system actions access
--| TODO: this module should be an overload on the default os.module
--| i.e. It should have a metatable after all functions are defined.
--| So wax.os.getenv = os.getenv
--| wax.os.setenv = wax.os.extension.setenv (FROM C)

local wax = require 'wax'
wax.os = require 'wax.os'

--$ wax.os.exec(command:string [, argv: string list]) : errorstr
--{ Replaces the current process by a new one.
do
--{
wax.os.exec('bash',{"-c", "ls -la /dev/null > /dev/null 2>&1"} )
os.exit(1) -- Will not trigger this error unless wax.os.exec has an error
--}
end
