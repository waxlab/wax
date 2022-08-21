/*************************************************\
||                                               ||
||        LUME - Lua Macros Extended             ||
||                                               ||
||    Copyright (C)  2022 Thadeu A C de Paula    ||
||                                               ||
|| This program is free software under the terms ||
|| of the GNU General Public License - version 3 ||
|| as published in  https://www.gnu.org/licenses ||
||                                               ||
\*************************************************/

#include <lua.h>
#include <lauxlib.h>



/* Abstraction over Lua versions for module exports */
#if ( LUA_VERSION_NUM < 502 )
  #define lume_export(L,n,t) luaL_register(L,n,t);
#else
  #define lume_export(L,n,t) luaL_newlib(L,t);
#endif



/* Internally used to push lume_field_** macros */
#define _lume_setfield(L,kt,k,vt,v) \
  lua_push ## kt((L),(k)); \
  lua_push ## vt((L),(v)); \
  lua_settable((L),(-3));

/* Only for string keys */
#define _lume_sethashtkey(L,k,vt,v) \
  lua_push ## vt((L),(v)); \
  lua_setfield(L, -2, k);



/* lume_setfieldXY(x,y) add keys to tables where:
** X represents the key type and its x value
** Y represents the content type and its y value,
**
** Example Lua     ----->  Example Lume
** t["hello"]=10           lume_setfield_si(L, "hello","10");
** t[10] = "hello"         lume_setfield_is(L, 10, "hello");
*/

#define lume_setfield_sb(L,k,v) _lume_sethashtkey((L),(k),boolean,(v));
#define lume_setfield_si(L,k,v) _lume_sethashtkey((L),(k),integer,(v));
#define lume_setfield_sn(L,k,v) _lume_sethashtkey((L),(k),number,(v));
#define lume_setfield_ss(L,k,v) _lume_sethashtkey((L),(k),string,(v));

#define lume_setfield_in(L,k,v) _lume_setfield((L),integer,(k),number,(v));
#define lume_setfield_ii(L,k,v) _lume_setfield((L),integer,(k),integer,(v));
#define lume_setfield_is(L,k,v) _lume_setfield((L),integer,(k),string,(v));
#define lume_setfield_ib(L,k,v) _lume_setfield((L),integer,(k),boolean,(v));



/*
** Create an userdata metatable and set its functions
**
** lume_newudatametatable(lua_State *L, char *udataname, luaL_Reg *funcs)
*/
#if ( LUA_VERSION_NUM < 502 )
  #define lume_newuserdata_mt(lua_State, udataname, funcs) \
    luaL_newmetatable((lua_State), (udataname)); \
    lua_pushvalue((lua_State), -1); \
    lua_setfield((lua_State),-2,"__index"); \
    luaL_register((lua_State) ,NULL, (funcs))
#else
  #define lume_newuserdata_mt(lua_State, udataname, funcs) \
    luaL_newmetatable((lua_State), (udataname)); \
    lua_pushvalue((lua_State), -1); \
    lua_setfield((lua_State),-2,"__index"); \
    luaL_setfuncs((lua_State), (funcs), 0);
#endif



/*
** Error macro that throws lua error
** Only can be catched with pcall
*/

#define lume_error(lua_State,condition,message) \
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
#define lume_failnil_m(lua_State,condition,message) \
  if ((condition)) {\
    lua_pushnil((lua_State)); \
    lua_pushstring((lua_State), (const char *)(message)); \
    return 2; \
  }


#define lume_failnil(L,condition) \
  lume_failnil_m(L, condition, strerror(errno))


#define lume_failboolean_m(lua_State,condition,message) \
  if ((condition)) {\
    lua_pushboolean(lua_State,0); \
    lua_pushstring((lua_State), (const char *)(message)); \
    return 2; \
  }


#define lume_failboolean(L,condition) \
  lume_failboolean_m(L, condition, strerror(errno))

