--[[
$ wax.lazy(name: string, module : table)

Lazy loader for module members. As your module grows,
you may have more specific and less used functions, or even
exclusive functions (using one doesn't use other). So, have
all its logic inside a module may sound unnecessary.

Also, some lower level functionality may fit in one function,
but can demand a longer logic on the C side. So a C module
can produce a single Lua function and act as a module function.

Example:

In module ``x``:
```
local module = {}
function module.a() return "A" end
function module.b() return "B" end
return (require "wax").lazy("x",module)
```

In module ``x.y``
```
return function() return "Y" end
```

Now you need only to require the module ``x``:
```
local x = require 'x'
x.a() -- prints "A"
x.b() -- prints "B"
x.y() -- prints "Y"
```

In the moment you call ``x.y()``, the function ``y`` doesn't
exist in the ``x`` module. So it tries to load from a ``x.y``
module.
--]]
--{
local lazy = require 'wax.lazy'

local x = {}
lazy('wax', x)

assert(x.lazy == lazy)
--}
