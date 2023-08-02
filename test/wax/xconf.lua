--[[
Explicit Configurations
-----------------------

``wax.xconf`` is a module to load configurations explicitly. The configurations
has a valid Lua syntax and are processed under a sandboxed environment that
receives only the functions to be used for configuration value parsing.

Confex proposes an improved way over the traditional use of plain Lua as
configurations because:

* Avoid duplicated entries.
* Keep the order how the data will be stored in final configuration
representation.
* Provide better error messages pointing what and where the error is on the
configuration file.

--$ wax.confex.loadfile(file:string, spec:table) : wax.ds.orecord
--$ wax.confex.load(conf:string, spec:table) : wax.ds.orecord
--]]


