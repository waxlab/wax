/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/waxlab/wax)
 */

#include "os.h"


/* int execvp(const char *file, char *const argv[]); */
static int wax_os_exec(lua_State *L) {
  char *argv[100];
  size_t idx = 0;
  argv[0] = (char *) luaL_checkstring(L,1);

  if (lua_istable(L, 2)) {
    for (idx=1; idx <= waxLua_rawlen(L,2); idx++) {
      lua_rawgeti(L, 2, idx);
      argv[idx] = (char *) luaL_checkstring(L, -1);
    }
  }

  argv[idx] = NULL;
  execvp(argv[0], argv);

  return 0;
}


/*
 * Module exported functions
 */

static const luaL_Reg wax_os[] = {
  {"exec", wax_os_exec},
  { NULL,  NULL       }
};


int luaopen_wax_os(lua_State *L) {
  waxLua_export(L, "wax.os", wax_os);
  return 1;
}
