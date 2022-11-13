/* Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/waxlab/wax)
 *
 *
 * This header stores macros that simplifies Lua data handling.
 * Using these macros you will write less code, avoid common mistakes
 * and, even you have a specialized code, you can use these as
 * reference of how to deeper stuffs are done
 */


#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#include <errno.h>


/*
 * waxL_pairXY(x,y) add keys to tables where:
 * X represents the key type and its x value
 * Y represents the content type and its y value,
 *
 * Example Lua     ----->  Example Lume
 * t["hello"]=10           waxL_pair_si(L, "hello","10");
 * t[10] = "hello"         waxL_pair_is(L, 10, "hello");
 */

#define waxL_pair_sb(lua_State, key, val) \
  iwaxL_sethashtkey((lua_State),(key),boolean,(val));
#define waxL_pair_si(lua_State, key, val) \
  iwaxL_sethashtkey((lua_State),(key),integer,(val));
#define waxL_pair_sn(lua_State, key, val) \
  iwaxL_sethashtkey((lua_State),(key),number, (val));
#define waxL_pair_ss(lua_State, key, val) \
  iwaxL_sethashtkey((lua_State),(key),string, (val));

#define waxL_pair_in(lua_State, key, val) \
  iwaxL_pair((lua_State),integer,(key),number, (val));
#define waxL_pair_ii(lua_State, key, val) \
  iwaxL_pair((lua_State),integer,(key),integer,(val));
#define waxL_pair_is(lua_State, key, val) \
  iwaxL_pair((lua_State),integer,(key),string, (val));
#define waxL_pair_ib(lua_State, key, val) \
  iwaxL_pair((lua_State),integer,(key),boolean,(val));



/* Creates an userdata metatable and set its functions */
#if ( LUA_VERSION_NUM < 502 )
  #define waxL_newuserdata_mt(lua_State, udataname, funcs) \
    luaL_newmetatable((lua_State), (udataname)); \
    lua_pushvalue((lua_State), -1); \
    lua_setfield((lua_State),-2,"__index"); \
    luaL_register((lua_State) ,NULL, (funcs))
#else
  #define waxL_newuserdata_mt(lua_State, udataname, funcs) \
    luaL_newmetatable((lua_State), (udataname)); \
    lua_pushvalue((lua_State), -1); \
    lua_setfield((lua_State),-2,"__index"); \
    luaL_setfuncs((lua_State), (funcs), 0);
#endif


/*
 * ERROR MACROS
 * Error macro that throws lua error
 * Only can be catched with pcall
 */

#define waxL_error(lua_State, msg) { \
  lua_pushstring((lua_State),(msg)); \
  lua_error(lua_State); \
}


#define waxL_assert(lua_State, cond, msg) \
  if (!(cond)) { \
    waxL_error(lua_State, msg); \
  }



/*
 * FAIL MACROS
 * Make function return immediately condition is fullfilled and
 * return default fail values (boolean false or nil)
 */
#define waxL_failnil_m(lua_State, cond, msg) \
  if ((cond)) {\
    lua_pushnil((lua_State)); \
    lua_pushstring((lua_State), (const char *)(msg)); \
    return 2; \
  }


#define waxL_failnil(L, cond) \
  waxL_failnil_m(L, cond, strerror(errno))


#define waxL_failboolean_m(lua_State, cond, msg) \
  if ((cond)) {\
    lua_pushboolean(lua_State,0); \
    lua_pushstring((lua_State), (const char *)(msg)); \
    return 2; \
  }


#define waxL_failboolean(L, cond) \
  waxL_failboolean_m(L, cond, strerror(errno))

/*
 * POLYFILL MACROS
 * Abstraction over Lua versions
 */
#if ( LUA_VERSION_NUM < 502 )
  #define waxL_rawlen(lua_State, index) \
    lua_objlen((lua_State), (index))

  #define waxL_export(lua_State, name, luaL_Reg) \
    luaL_register((lua_State), (name), (luaL_Reg));
#else
  #define waxL_rawlen(lua_State, index) \
    lua_rawlen((lua_State), (index))

  #define waxL_export(lua_State, name, luaL_Reg) \
    luaL_newlib((lua_State), (luaL_Reg))

#endif


/*
 * DEFINITIONS
 */

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



/*
 * INTERNAL MACROS
 * The following are macro helpers intended for internal use only.
 * They are not documented and can be changed in future.
 */

/* For all Lua types */
#define iwaxL_pair(lua_State, keytype, key, valtype, val) \
  lua_push ## keytype((lua_State),(key)); \
  lua_push ## valtype((lua_State),(val)); \
  lua_settable((lua_State),(-3));

/* Only for string keys */
#define iwaxL_sethashtkey(lua_State, key, valtype, val) \
  lua_push ## valtype((lua_State),(val)); \
  lua_setfield(L, -2, key);

