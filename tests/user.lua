--   Wax Project -- Axa Lua Development  --
--     Copyright 2022 Thadeu de Paula    --
--     https://github.com/axa-dev/wax    --
--       Licensed under MIT License      --

--| ## wax.user
--| Module with user information
--|
--| Most of time the info retrieved through this module is the same that the
--| obtained from environment variables (Ex. `os.getenv("USER")`) but consider
--| that environment some environment variables can be tricked and allows
--| different values from the real, i.e, the `HOME` (as well `USER` or `SHELL`
--| environment variables) can be forced to a value other than the actually
--| logged user.

local wax = {
  user = require("wax.user")
}


do
--@ wax.user.id( [username: string] ) : number | nil
--{ Obtains the user id specified by the `username` argument.
--| If called without arguments, retrieves the current system user id.
--| Returns the user id number on success or nil otherwise

  local uid = wax.user.id()
  assert( type(uid) == "number")
  assert( uid >= 0 )
  if uid ~= 0 then
    assert( wax.user.id("root") == 0 )
  else
    assert( wax.user.id("testuser") == 2000 )
  end
  assert( wax.user.id("") == nil )
  assert( wax.user.id("Some invalid user name") == nil )
--}
end


do
--@ wax.user.name( [userid: number] ) : string | nil
--{ Obtains the name of the user specified the `userid` argument
--| If called without arguments, retrieves the current system user id.
--| Returns the user name string on success or nil otherwise
  if wax.user.id() == 0 then
    assert( wax.user.name() == "root" )
    assert( wax.user.name(2000) == "testuser" )
  else
    assert( wax.user.name() ~= "root" )
    assert( wax.user.name(0) == "root" )
  end

  assert( wax.user.name(65536) == nil)    -- Linux < 2.4 until 65535
  assert( wax.user.name(10^9 * 5) == nil) -- Linux >= 2.4 until 4 billion
--}
end


do
--@ wax.user.home( [user: number|string] ) : string | nil
--{ Obtains the user home directory.
--| If called with user argument of type number, retrieves by user id.
--| If called with user argument of type string, retrieves by user name.
--| Returns the user home directory name on success or nil otherwise
  local homedir = wax.user.home()
  assert( type(homedir) == "string" and #homedir > 0)

  if wax.user.id() == 0 then
    assert(wax.user.home() == "/root")
    assert(wax.user.home("testuser") == "/home/testuser")
    assert(wax.user.home(2000) == "/home/testuser")
  end

  assert(wax.user.home(0) == "/root")
  assert(wax.user.home("root") == "/root")

  assert(wax.user.home(10^9 * 5) == nil)
  assert(wax.user.home("some inexistent user") == nil)
--}
end


do
--@ wax.user.shell( [user: number|string] ) : string
--{ Obtains the user shell binary path.
--| If called with user argument of type number, retrieves by user id.
--| If called with user argument of type string, retrieves by user name.
--| Returns the shell path string (ex. "/bin/bash") on success or nil otherwise
  local sh = wax.user.shell()
  assert( type(sh) == "string" )
  assert( #sh > 0 )

  sh = wax.user.shell(0)
  assert( type(sh) == "string" )
  assert( #sh > 0 )

  sh = wax.user.shell("testuser")
  if sh then
    assert(type(sh) == "string")
    assert(#sh > 0)
    assert(sh == wax.user.shell(2000))
  end

  assert(wax.user.shell(10^9 * 5) == nil)
  assert(wax.user.shell("some inexistent user") == nil)
--}
end


do
--@ wax.user.groups( [user: number|string] ) : { number, }
--{ Obtains the list of the groups the the user belongs to.
--| If called with user argument of type number, retrieves by user id.
--| If called with user argument of type string, retrieves by user name.
--| Returns a list with group ids on success or nil otherwise
  local groups

  groups = wax.user.groups()
  assert(#groups > 0)
  for _, groupId in ipairs(groups) do
    assert( type(groupId ) == "number" and groupId >= 0)
  end

  groups = wax.user.groups("root")
  assert(#groups > 0)
  for _, groupId in ipairs(groups) do
    assert( type(groupId ) == "number" and groupId >= 0)
  end

  if wax.user.id("testuser") then
    groups = wax.user.groups("testuser")
    assert(#groups > 0)
    for _, groupId in ipairs(groups) do
      assert( type(groupId ) == "number" and groupId >= 0)
    end
  end

  assert( wax.user.groups(10^9 * 5) == nil)
  assert( wax.user.groups("some inexistent user") == nil)
--}
end


print("\n*** wax.user OK! *** ".._VERSION.." ***");
