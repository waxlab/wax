/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/w8lab/wax)
 */

#include "c8l/w8l.h"
#include <stddef.h>
#include <stdio.h>
#include "unistd.h"
#include "string.h"
#include "errno.h"

/* //// DECLARATION //// */


int luaopen_wax_os(lua_State *L);

Lua wax_os_exec(lua_State *L);

LuaReg wax_os[] = {
  {"exec", wax_os_exec},
  { NULL,  NULL       }
};

/* //// IMPLEMENTATION //// */

int luaopen_wax_os(lua_State *L) {
  w8l_export(L, "wax.os", wax_os);
  return 1;
}

static int wax_os_exec(lua_State *L) {
  char *argv[100];
  size_t idx = 0;
  argv[0] = (char *) luaL_checkstring(L,1);

  if (lua_istable(L, 2)) {
    for (idx=1; idx <= w8l_rawlen(L,2); idx++) {
      lua_rawgeti(L, 2, idx);
      argv[idx] = (char *) luaL_checkstring(L, -1);
    }
  }

  argv[idx] = NULL;
  execvp(argv[0], argv);

  return 0;
}


/* vim: set fdm=indent fdn=1 ts=2 sts=2 sw=2: */
