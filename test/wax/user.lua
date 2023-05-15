-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--| ## wax.user
--| Operating system user handling library.
--|
--| Most of time the info retrieved through this module is the same that the
--| obtained from environment variables (Ex. `os.getenv("USER")`) but consider
--| that environment some environment variables can be tricked and allows
--| different values from the real, i.e, the `HOME` (as well `USER` or `SHELL`
--| environment variables) can be forced to a value other than the actually
--| logged user.

--| Basic usage:
local wax  = require("wax")
local user = require("wax.user")


--$ user.id( [username: string] ) : number | nil
--| Obtains the user id specified by the `username` argument.
do
--| If called without arguments, retrieves the current system user id.
--| Returns the user id number on success or nil otherwise
--{
  local uid = user.id()
  assert( type(uid) == "number")
  assert( uid >= 0 )
  if uid ~= 0 then
    assert( user.id("root") == 0 )
  else
    assert( user.id("testuser") == 2000 )
  end
  assert( user.id("") == nil )
  assert( user.id("Some invalid user name") == nil )
--}
end


--$ user.name( [userid: number] ) : string | nil
--| Obtains the name of the user specified the `userid` argument
do
--| If called without arguments, retrieves the current system user id.
--| Returns the user name string on success or nil otherwise
--{
  if user.id() == 0 then
    assert( user.name() == "root" )
    assert( user.name(2000) == "testuser" )
  else
    assert( user.name() ~= "root" )
    assert( user.name(0) == "root" )
  end

  assert( user.name(65536) == nil)    -- Linux < 2.4 until 65535
  assert( user.name(10^9 * 5) == nil) -- Linux >= 2.4 until 4 billion
--}
end


--$ user.home( [user: number|string] ) : string | nil
--| Obtains the user home directory.
do
--| If called with user argument of type number, retrieves by user id.
--| If called with user argument of type string, retrieves by user name.
--| Returns the user home directory name on success or nil otherwise
--{
  local homedir = user.home()
  assert( type(homedir) == "string" and #homedir > 0)

  if user.id() == 0 then
    assert(user.home() == "/root")
    assert(user.home("testuser") == "/home/testuser")
    assert(user.home(2000) == "/home/testuser")
  end

  assert(user.home(0) == "/root")
  assert(user.home("root") == "/root")

  assert(user.home(10^9 * 5) == nil)
  assert(user.home("some inexistent user") == nil)
--}
end


--$ user.shell( [user: number|string] ) : string
--| Obtains the user shell binary path.
do
--| If called with user argument of type number, retrieves by user id.
--| If called with user argument of type string, retrieves by user name.
--| Returns the shell path string (ex. "/bin/bash") on success or nil otherwise
--{
  local sh = user.shell()
  assert( type(sh) == "string" )
  assert( #sh > 0 )

  sh = user.shell(0)
  assert( type(sh) == "string" )
  assert( #sh > 0 )

  sh = user.shell("testuser")
  if sh then
    assert(type(sh) == "string")
    assert(#sh > 0)
    assert(sh == user.shell(2000))
  end

  assert(user.shell(10^9 * 5) == nil)
  assert(user.shell("some inexistent user") == nil)
--}
end


--$ user.groups( [user: number|string] ) : { number, }
--| Obtains the list of the groups the the user belongs to.
do
--| If called with user argument of type number, retrieves by user id.
--| If called with user argument of type string, retrieves by user name.
--| Returns a list with group ids on success or nil otherwise
--{
  local groups

  groups = user.groups()
  assert(#groups > 0)
  for _, groupId in ipairs(groups) do
    assert( type(groupId ) == "number" and groupId >= 0)
  end

  groups = user.groups("root")
  assert(#groups > 0)
  for _, groupId in ipairs(groups) do
    assert( type(groupId ) == "number" and groupId >= 0)
  end

  if user.id("testuser") then
    groups = user.groups("testuser")
    assert(#groups > 0)
    for _, groupId in ipairs(groups) do
      assert( type(groupId ) == "number" and groupId >= 0)
    end
  end

  assert( user.groups(10^9 * 5) == nil)
  assert( user.groups("some inexistent user") == nil)
--}
end

