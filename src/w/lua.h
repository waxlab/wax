/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/

/*
//## w/lua.h - Macros to help Lua C Modules writting
//|
//| This header contains a set of macros, functions and inlined functions
//| to automate boring Lua stack manipulation or the ones most prone to error.
//|
//| Also tries to provide some standardization on error handling or error
//| returning by functions (the pattern of double return).
*/

#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#include <errno.h>
#include <sys/param.h>
#include <stdarg.h>


#define Lua static int
#define LuaReg static const luaL_Reg

/*
//$ void wLua_pair_KV(lua_State* L, K: V)
//| Macro that add keys to tables where KV is the variant meaning:
//| K the key type and k its value;
//| V the value type and its v value,
//|
//|     Example Lua     ----->  C using l8n
//|     t["hello"]=10           wLua_pair_si(L, "hello", 10);
//|     t[10] = "hello"         wLua_pair_is(L, 10, "hello");
//|
//| K can be one of s (string) or i (integer).
//| V can be one of b (boolean), i (integer), n (number),
//| s (string) or lu (lightuserdata)
//|
//| Available functions:
//|
//| - `wLua_pairs_sb(L, const char *k, int v)`
//|    Lua string key and boolean value.
//|
//| - `wLua_pairs_si(L, const char *k, lua_Integer v)`
//|    Lua string key and integer value.
//|
//| - `wLua_pairs_sn(L, const char *k, lua_Number v)`
//|    Lua string key and number value.
//|
//| - `wLua_pairs_ss(L, const char *k, const char *v)`
//|    Lua string key and string value
//|
//| - `wLua_pairs_slu(L, const char *k, void *v)`
//|    Lua string key and lightuserdata value
//|
//| - `wLua_pair_ib(L, lua_Integer k, int v)`
//|    Lua string key and boolean value
//|
//| - `wLua_pair_ii(L, lua_Integer k, lua_Integer v)`
//|    Lua string key and integer value
//|
//| - `wLua_pair_in(L, lua_Integer k, lua_Number *v)`
//|    Lua string key and number value
//|
//| - `wLua_pair_is(L, lua_Integer k, const char *v)`
//|    Lua string key and string value
//|
//| - `wLua_pair_ilu(L,lua_Integer k, void *v)`
//|    Lua string key and lightuserdata value
*/
#define wLua_pair_sb(L, k, v) \
  _wLua_fpair((L),(k),boolean,(v))

#define wLua_pair_si(L, k, v) \
  _wLua_fpair((L),(k),integer,(v))

#define wLua_pair_sn(L, k, v) \
  _wLua_fpair((L),(k),number, (v))

#define wLua_pair_ss(L, k, v) \
  _wLua_fpair((L),(k),string, (v))

#define wLua_pair_slu(L, k, v) \
  _wLua_fpair((L),(k),lightuserdata, (v))

#define wLua_pair_ib(L, i, v) \
  _wLua_pair((L),integer,(i),boolean,(v))

#define wLua_pair_ii(L, i, v) \
  _wLua_pair((L),integer,(i),integer,(v))

#define wLua_pair_in(L, i, v) \
  _wLua_pair((L),integer,(i),number, (v))

#define wLua_pair_is(L, i, v) \
  _wLua_pair((L),integer,(i),string, (v))

#define wLua_pair_ilu(L, i, v) \
  _wLua_pair((L),integer,(i),lightuserdata,(v))

    /* For all Lua types */
    #define _wLua_pair(lua_State, ktype, k, vtype, v) (\
      lua_push ## ktype((lua_State),(k)), \
      lua_push ## vtype((lua_State),(v)), \
      lua_settable((lua_State),(-3))      \
    )

    /* Only for string keys */
    #define _wLua_fpair(lua_State, k, vtype, v) (\
      lua_push ## vtype((lua_State),(v)), \
      lua_setfield(L, -2, k)              \
    )

/*
//$ void wLua_newuserdata_mt(lua_State *L, const char *n, luaL_Reg *r)
//|
//| Macro that creates an userdatum metatable and set its functions.
//| The functions are in a traditional luaL_Reg and `n` is the string used to
//| identify through the code.
//| Also, Lua 5.2+, can uses the identifier name for userdata on Lua side.
*/
#if ( LUA_VERSION_NUM < 502 )
  #define wLua_newuserdata_mt(L, n, r) ( \
    luaL_newmetatable((L), (n)),        \
    lua_pushvalue((L), -1),             \
    lua_setfield((L),-2,"__index"),     \
    luaL_register((L) ,NULL, (r))       \
  )
#else
  #define wLua_newuserdata_mt(L, n, r) ( \
    luaL_newmetatable((L), (n)),        \
    lua_pushvalue((L), -1),             \
    lua_setfield((L),-2,"__index"),     \
    lua_pushstring((L), n),             \
    lua_setfield((L),-2,"__name"),      \
    luaL_setfuncs((L), (r), 0)          \
  )
#endif



/*
//$ int wLua_rawlen(L, i)
//| Get the raw length of a table at index `i` of stack.
//| Use it instead of lua_rawlen to support older versions.
*/
#if ( LUA_VERSION_NUM < 502 )
  #define wLua_rawlen(L, i) \
    lua_objlen((L), (i))
#else
  #define wLua_rawlen(L, i) \
    lua_rawlen((L), (i))
#endif

/*
//$ wLua_export(lua_State *L, LuaReg r)
//| Create a new Lua module from the register `r`
*/
#if ( LUA_VERSION_NUM < 502 )
  #define wLua_export(L, r) (lua_newtable(L), luaL_register((L), NULL, (r)))
#else
  #define wLua_export(L, r) luaL_newlib((L), (r))
#endif


// Not used, yet.

#if defined(_WIN32) || defined(WIN64)
  #define PLAT_WINDOWS
#elif __unix__
  #define PLAT_POSIX
#endif


#ifndef PATH_MAX
  #ifdef NAME_MAX
    const int PATH_MAX = NAME_MAX;
  #elif MAXPATHLEN
    const int PATH_MAX = MAXPATHLEN;
  #endif
#endif


/******************\
** ERROR HANDLING **
\******************/

/*
//$ void wLua_error(lua_State *L, char* msg, ...)
//| Breaks the execution throwing a Lua error with the `msg` message.
//| The message can be informed like in printf, i.e, with `msg` containing
//| the template to be filled by subsequent parameters.
*/
void wLua_error(lua_State *L, char *fmt, ...) {
  va_list va;
  char msg[1024];
  va_start(va, fmt);
  vsnprintf(msg, 1024, fmt, va);
  va_end(va);
  lua_pushstring((L), msg);
  lua_error(L);
}

/*
//$ void wLua_assert(lua_State *L, int cond, char *msg, ...)
//| Tests the `cnd` assertion and if it is false then throws a Lua error.
//| As `wLua_error()`, it allows the message template with replacements.
*/
#define wLua_assert(L, cnd, ...) \
  if (!(cnd)) { wLua_error(L, __VA_ARGS__); }


/********************\
** FAILURE HANDLING **
\********************/

/*
 * Intended to help Lua function return on errors,
 * when it results in a double return: nil, <somestring>
 */

/*
//$ void wLua_failnil_m(lua_State *L, int cond, char *msg)
//| It evaluates the `cond` and make the Lua function where it is called
//| returns a nil followed by `msg` message.
*/
#define wLua_failnil_m(L, cond, msg)          \
  if ((cond)) {                               \
    lua_pushnil((L));                         \
    lua_pushstring((L), (const char *)(msg)); \
    return 2;                                 \
  }

/*
//$ void wLua_failnil(lua_State *L, int cond)
//| Evaluates condition `cond` and, in case of error, make the Lua function
//| where it is called return nil followed by the message of `strerror(errno)`
*/
#define wLua_failnil(L, cond) \
  wLua_failnil_m(L, cond, strerror(errno))

/*
//$ void wLua_failboolean_m(lua_State *L, int cond, char *msg)
//| Same as `wLua_failboolean` but you can specify a custom literal message.
//| It evaluates the `cond` and make the Lua function where it is called
//| returns a Lua boolean and the `msg` message.
*/
#define wLua_failboolean_m(lua_State, cond, msg)      \
  if ((cond)) {                                       \
    lua_pushboolean(lua_State,0);                     \
    lua_pushstring((lua_State), (const char *)(msg)); \
    return 2;                                         \
  }

/*
//$ void wLua_failboolean(lua_State *L, int cond)
//| Evaluates condition `cond` and, in case of error, make the Lua function
//| where it is called return a Lua boolean and the message of `strerror(errno)`
*/
#define wLua_failboolean(L, cond) \
  wLua_failboolean_m(L, cond, strerror(errno))

