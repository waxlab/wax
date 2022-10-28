/*
** Wax
** A waxing Lua Standard Library
**
** Copyright (C) 2022 Thadeu A C de Paula
** (https://github.com/waxlab/wax)
*/

/*
** This header stores macros that simplifies Lua data handling.
** Using these macros you will write less code, avoid common mistakes
** and, even you have a specialized code, you can use these as
** reference of how to deeper stuffs are done
*/


#include <lua.h>
#include <lauxlib.h>


/* Abstraction over Lua versions for module exports */
#if ( LUA_VERSION_NUM < 502 )
  #define waxLua_rawlen lua_objlen
  #define waxLua_export luaL_register
#else
  #define waxLua_rawlen lua_rawlen
  #define waxLua_export(L,n,t) luaL_newlib(L,t);
#endif



/* Internally used to push waxLua_field_** macros */
#define _waxLua_setfield(L,kt,k,vt,v) \
  lua_push ## kt((L),(k)); \
  lua_push ## vt((L),(v)); \
  lua_settable((L),(-3));

/* Only for string keys */
#define _waxLua_sethashtkey(L,k,vt,v) \
  lua_push ## vt((L),(v)); \
  lua_setfield(L, -2, k);



/* waxLua_setfieldXY(x,y) add keys to tables where:
** X represents the key type and its x value
** Y represents the content type and its y value,
**
** Example Lua     ----->  Example Lume
** t["hello"]=10           waxLua_setfield_si(L, "hello","10");
** t[10] = "hello"         waxLua_setfield_is(L, 10, "hello");
*/

#define waxLua_setfield_sb(L,k,v) _waxLua_sethashtkey((L),(k),boolean,(v));
#define waxLua_setfield_si(L,k,v) _waxLua_sethashtkey((L),(k),integer,(v));
#define waxLua_setfield_sn(L,k,v) _waxLua_sethashtkey((L),(k),number,(v));
#define waxLua_setfield_ss(L,k,v) _waxLua_sethashtkey((L),(k),string,(v));

#define waxLua_setfield_in(L,k,v) _waxLua_setfield((L),integer,(k),number,(v));
#define waxLua_setfield_ii(L,k,v) _waxLua_setfield((L),integer,(k),integer,(v));
#define waxLua_setfield_is(L,k,v) _waxLua_setfield((L),integer,(k),string,(v));
#define waxLua_setfield_ib(L,k,v) _waxLua_setfield((L),integer,(k),boolean,(v));



/*
** Create an userdata metatable and set its functions
**
** waxLua_newudatametatable(lua_State *L, char *udataname, luaL_Reg *funcs)
*/
#if ( LUA_VERSION_NUM < 502 )
  #define waxLua_newuserdata_mt(lua_State, udataname, funcs) \
    luaL_newmetatable((lua_State), (udataname)); \
    lua_pushvalue((lua_State), -1); \
    lua_setfield((lua_State),-2,"__index"); \
    luaL_register((lua_State) ,NULL, (funcs))
#else
  #define waxLua_newuserdata_mt(lua_State, udataname, funcs) \
    luaL_newmetatable((lua_State), (udataname)); \
    lua_pushvalue((lua_State), -1); \
    lua_setfield((lua_State),-2,"__index"); \
    luaL_setfuncs((lua_State), (funcs), 0);
#endif


/*
** Error macro that throws lua error
** Only can be catched with pcall
*/

#define waxLua_error(lua_State,condition,message) \
  if ((condition)) { \
    lua_pushstring((lua_State),(message)); \
    lua_error(lua_State); \
    return 0; \
  }



/*
** Fail macros
** Make function return immediately condition is fullfilled and
** return default fail values (boolean false or nil)
*/
#define waxLua_failnil_m(lua_State,condition,message) \
  if ((condition)) {\
    lua_pushnil((lua_State)); \
    lua_pushstring((lua_State), (const char *)(message)); \
    return 2; \
  }


#define waxLua_failnil(L,condition) \
  waxLua_failnil_m(L, condition, strerror(errno))


#define waxLua_failboolean_m(lua_State,condition,message) \
  if ((condition)) {\
    lua_pushboolean(lua_State,0); \
    lua_pushstring((lua_State), (const char *)(message)); \
    return 2; \
  }


#define waxLua_failboolean(L,condition) \
  waxLua_failboolean_m(L, condition, strerror(errno))

/*
** Other polyfills for oldies
*/
#if ( LUA_VERSION_NUM < 502 )
  #define lua_rawlen(L, i) lua_objlen(L,i)
#endif


/*
** DEFINITIONS
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

