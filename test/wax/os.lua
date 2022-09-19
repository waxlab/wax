--| ## wax.os
--| Operating system actions access
--| TODO: this module should be an overload on the default os.module
--| i.e. It should have a metatable after all functions are defined.
--| So wax.os.getenv = os.getenv
--| wax.os.setenv = wax.os.extension.setenv (FROM C)


do
--@ wax.os.exec(command:string [, argv: string list]) : errorstr
--{ Replaces the current process by a new one.
local waxos = require 'wax.os'

waxos.exec('bash',{"-c", "ls -la /dev/null", ">/dev/null"} )
os.exit(1)


--}
end


