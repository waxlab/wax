/*
** Wax
** A waxing Lua Standard Library
**
** Copyright (C) 2022 Thadeu A C de Paula
** (https://github.com/luawax/wax)
*/

#include "defs.h"

int unimplemented(lua_State *L, ...) {
  lua_pushnil(L);
  return 1;
}
