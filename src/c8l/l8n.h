// Wax
// A waxing Lua Standard Library
//
// Copyright (C) 2022 Thadeu A C de Paula
// (https://github.com/l8nab/wax)


//| # l8n.h - Loon C library header
//|
//| This header stores macros used to simplify the Lua C modules writting.
//|
//| - Less code writing, less distraction, less prone to error.
//| - Simple code reading, so you promptly knows what is doing on Lua stack.
//| - Abstraction on different Lua versions, so you can write one code and
//|   compile to different Lua versions.


#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#include <errno.h>
#include <sys/param.h>


#define Lua static int
#define LuaReg static const luaL_Reg


//$ void l8n_pair_KV(L, k, v)
//| Macro that add keys to tables where KV is the variant meaning:
//| K the key type and k its value
//| V the value type and its v value,
//|
//|     Example Lua     ----->  C using l8n
//|     t["hello"]=10           l8n_pair_si(L, "hello", 10);
//|     t[10] = "hello"         l8n_pair_is(L, 10, "hello");
//|
//| K can be one of s (string) or i (integer).
//| V can be one of b (boolean), i (integer), n (number),
//| s (string) or lu (lightuserdata)
#define l8n_pair_sb(L, k, v) \
	_l8n_fpair((L),(k),boolean,(v))

#define l8n_pair_si(L, k, v) \
	_l8n_fpair((L),(k),integer,(v))

#define l8n_pair_sn(L, k, v) \
	_l8n_fpair((L),(k),number, (v))

#define l8n_pair_ss(L, k, v) \
	_l8n_fpair((L),(k),string, (v))

#define l8n_pair_slu(L, k, v) \
	_l8n_fpair((L),(k),lightuserdata, (v))

#define l8n_pair_in(L, i, v) \
	_l8n_pair((L),integer,(i),number, (v))

#define l8n_pair_ii(L, i, v) \
	_l8n_pair((L),integer,(i),integer,(v))

#define l8n_pair_is(L, i, v) \
	_l8n_pair((L),integer,(i),string, (v))

#define l8n_pair_ib(L, i, v) \
	_l8n_pair((L),integer,(i),boolean,(v))

#define l8n_pair_ilu(L, i, v) \
	_l8n_pair((L),integer,(i),lightuserdata,(v))

		/* For all Lua types */
		#define _l8n_pair(lua_State, ktype, k, vtype, v) (\
			lua_push ## ktype((lua_State),(k)), \
			lua_push ## vtype((lua_State),(v)), \
			lua_settable((lua_State),(-3))      \
		)

		/* Only for string keys */
		#define _l8n_fpair(lua_State, k, vtype, v) (\
			lua_push ## vtype((lua_State),(v)), \
			lua_setfield(L, -2, k)              \
		)


//$ void l8n_newuserdata_mt(lua_State *L, const char *n, luaL_Reg *r)
//|
//| Macro that creates an userdatum metatable and set its functions.
//| The functions are in a traditional luaL_Reg and `n` is the string used to
//| identify through the code.
//| Also, Lua 5.2+, can uses the identifier name for userdata on Lua side.
#if ( LUA_VERSION_NUM < 502 )
	#define l8n_newuserdata_mt(L, n, r) ( \
		luaL_newmetatable((L), (n)),        \
		lua_pushvalue((L), -1),             \
		lua_setfield((L),-2,"__index"),     \
		luaL_register((L) ,NULL, (r))       \
	)
#else
	#define l8n_newuserdata_mt(L, n, r) ( \
		luaL_newmetatable((L), (n)),        \
		lua_pushvalue((L), -1),             \
		lua_setfield((L),-2,"__index"),     \
		lua_pushstring((L), n),             \
		lua_setfield((L),-2,"__name"),      \
		luaL_setfuncs((L), (r), 0)          \
	)
#endif


#define l8n_failboolean(L, cnd) \
	l8n_failboolean_m(L, cnd, strerror(errno))


//$ int l8n_rawlen(L, i)
//| Get the raw length of a table at index `i` of stack.
//| Use it instead of lua_rawlen to support older versions.
#if ( LUA_VERSION_NUM < 502 )
	#define l8n_rawlen(L, i) \
		lua_objlen((L), (i))
#else
	#define l8n_rawlen(L, i) \
		lua_rawlen((L), (i))
#endif


//$ l8n_export(L, n, r)
//| Create a new Lua module from the register `r` with name `n`
#if ( LUA_VERSION_NUM < 502 )
	#define l8n_export(L, n, r) \
		luaL_register((L), (n), (r))
#else
	#define l8n_export(L, n, r) \
		luaL_newlib((L), (r))
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


// ------------------------------------------------------------
//
// From now to end, still used, but in process of obsolescence.
// So, undocumented.

// ERROR MACROS
// Error macro that throws lua error
// Only can be catched with pcall

#define l8n_error(L, msg) {  \
	lua_pushstring((L),(msg)); \
	lua_error(L);              \
}


#define l8n_assert(L, cnd, msg) \
	if (!(cnd)) {                 \
		l8n_error(L, msg);          \
	}

// FAIL MACROS
//
// Make function return immediately condition is fullfilled and
// return default fail values (boolean false or nil)

#define l8n_failnil_m(L, cnd, msg)            \
	if ((cnd)) {                                \
		lua_pushnil((L));                         \
		lua_pushstring((L), (const char *)(msg)); \
		return 2;                                 \
	}


#define l8n_failnil(L, cnd) \
	l8n_failnil_m(L, cnd, strerror(errno))


#define l8n_failboolean_m(lua_State, cond, msg)       \
	if ((cond)) {                                       \
		lua_pushboolean(lua_State,0);                     \
		lua_pushstring((lua_State), (const char *)(msg)); \
		return 2;                                         \
	}
