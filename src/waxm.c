/*
** Wax Macros
** A waxing Lua Standard Library
**
** Copyright (C) 2022 Thadeu A C de Paula
** (https://github.com/waxlab/wax)
*/

#include "waxm.h"

int unimplemented(lua_State *L, ...) {
  lua_pushnil(L);
  return 1;
}
