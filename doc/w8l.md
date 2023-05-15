# Wool : C Lua Library Dev

To use it, include the `waxL/waxL.h` header.

It is divided into different sets of utilities. You can easily spot their
target looking at their prefix:

- `waxL_` are to simplify the code on Lua C API.
- `waxC_` are to simplify the common, verbose and complex C logic.

To easily explain prefixes, every `···` presense in the macro name represents
that it is a explanation on a prefix.


###### `waxL_export(lua_State *L, char *name, luaL_Reg *register)`

Register module functions.
  - Lua 5.1 : `luaL_register`
  - Lua 5.2+: `luaL_newlib`


###### `waxL_assert(lua_State *L, condition, char *msg)`

Throws a Lua error with the message `msg` if the `condition` is not evaluate to
true. `condition` is any expression that can be used in an ordinary `if`
statement.

It is intended to be used always when writing a Lua function as it includes and
an `return 0;`


###### `waxL_error(lua_State *L, char *msg)`

Throws a Lua error with the message. It is intended to be always used inside a
Lua C function, as it will always will include an `return 0;`


###### `waxL_fail···`

These macros standardize the Lua function returns and make clear on C side what
is happening.


###### `waxL_fail(lua_State *L, condition)`

Make Lua function return two values, `nil` and the `strerror(errno)` string,
returning immediately from the C function.


###### `waxL_failnil_m(lua_State *L, condition, char *msg)`

Make Lua function return two values, `nil` and the `msg` string, returning
immediately from the C function.


###### `waxL_failbool(lua_State *L, condition)`

Make Lua function return two values, `false` and the `strerror(errno)`,
returning immediately from the C function.

###### `waxL_failbool_m(lua_State *L, condition, char *msg)`

Make Lua function return two values, `false` and the `msg` string, returning
immediately from the C function.


###### `waxL_newuserdata_mt(lua_State *L, char *name, luaL_Reg *methods)`

Registers a new userdata `char *name` containing the methods of the
`luaL_Reg *methods`.


###### `waxL_rawlen(lua_State *L, index)`

Gets the length of the stack `index`, be it a string (like `#`) or the length
of a table ignoring its metamethods.

- Lua 5.1 : `lua_objlen`
- Lua 5.2+: `lua_rawlen`


###### `waxL_pair_···(lua_State *L, @key, @value)`

Helpers to set key/value to the table on top of stack; Basically `···` consists
of two letters. The first being `s` or `i`, for string or integer keys and the
second letter is for the value part of the table being one of `b`,`i`,`n` or `s`
respectively for `boolean`, `integer`, `number` or `string` Lya types.


###### `waxL_pair_̣s···(lua_State *L, char *key, @value)`

Helpers to set key/value to the table where keys are strings;


###### `waxL_pair_i···(lua_State *L, int index, @value)`

Helpers to set index/value to the table where indexes are integers;

###### `waxL_pair_ib(lua_State *L, int key, int value)`
###### `waxL_pair_ii(lua_State *L, int key, int value)`
###### `waxL_pair_in(lua_State *L, int key, int/float value)`
###### `waxL_pair_is(lua_State *L, int key, char *value)`
###### `waxL_pair_sb(lua_State *L, char *index, int value)`
###### `waxL_pair_si(lua_State *L, char *index, int value)`
###### `waxL_pair_sn(lua_State *L, char *index, int/float value)`
###### `waxL_pair_ss(lua_State *L, char *index, char *value)`
