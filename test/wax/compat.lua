-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--| # wax.compat
--| Tools to enhance compatibility with different Lua versions.
--|
--| Lua module to abstract differences between Lua versions.
--| It allows you to some new Lua standard library resources in older
--| Lua versions as well as keep using some old functions that
--| disappeared or somewhat changed in signature and naming.

--| Basic usage:
--{
local compat = require 'wax.compat'
--}


--$ compat.load(chunk: string, env: table)
--| Load the string chunk `chunk` as a function using `env` table as environment
do
--{
  local env = {}
  local fn, err = compat.load([[myvar = { key = "value" }]], env )
  assert(fn() == nil, err == nil)  -- Function does not return anything
  assert(env.myvar.key == "value") -- But its environment is affected

  local fn, err = compat.load([[ return myvar.key .. myvar.key ]], env )
  assert(fn() == 'valuevalue')
--}
end


--$ compat.loadfile(filename: string, envt: table)
--| Does the same as the `compat.load` but loading from a file instead.
do
local luafile = require 'wax.fs'.getcwd()..'/etc/example/luafile.lua'
--{
  local env = {}
  local fn, err = compat.loadfile(luafile, env)
  assert(fn() == 'returned value')
  assert(env.somevar == 'some value')
--}
end


--$ compat.setfenv(fn: function, envt: table)
--| Set the `envt` table as environment for the function `fn`
do
--{
local function fn() return value end
compat.setfenv(fn,{value=10})
assert(fn() == 10)
--}
end
