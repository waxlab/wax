/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/
#define _POSIX_C_SOURCE 200112L

#include "../w/lua.h"
#include "../w/arr.h"
#include <stddef.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>

/* //// DECLARATION //// */


int
luaopen_wax_os_initc(lua_State *L);

Lua
wax_os_exec(lua_State *L),
wax_os_setenv(lua_State *L);

LuaReg module[] = {
  {"exec",   wax_os_exec  },
  {"setenv", wax_os_setenv},
  { NULL,    NULL         }
};

/* //// IMPLEMENTATION //// */

int luaopen_wax_os_initc(lua_State *L) {
  wLua_export(L, module);
  return 1;
}

Lua
wax_os_exec(lua_State *L) {
  char **argv;
  size_t idx = 0;
  wLua_assert(L, (argv = wArr_new(*argv,2)) != NULL, strerror(errno));
  wArr_push(argv, (char *)luaL_checkstring(L,1));

  if (lua_istable(L, 2)) {
    for (idx=1; idx <= wLua_rawlen(L,2); idx++) {
      lua_rawgeti(L, 2, idx);
      wArr_push(argv, (char *)luaL_checkstring(L, -1));
    }
  }
  wArr_push(argv, NULL);
  execvp(argv[0], argv);
  wArr_free(argv);

  // Only here on error. If execvp succeds, this block will never run
  lua_pushstring(L,strerror(errno));
  return 1;
}

Lua
wax_os_setenv(lua_State *L) {
  const char
    *name = luaL_checkstring(L,1),
    *value = luaL_checkstring(L,2);

  if (setenv(name,value,1) != 0) {
    lua_pushboolean(L, 0);
    lua_pushstring(L,strerror(errno));
    return 2;
  } else {
    lua_pushboolean(L, 1);
    return 1;
  }
}
