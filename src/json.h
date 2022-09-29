/*
** Wax
** A waxing Lua Standard Library
**
** Copyright (C) 2022 Thadeu A C de Paula
** (https://github.com/waxlab/wax)
*/

#include "waxm.h"
#define CJSON_NESTING_LIMIT INT_MAX
#include "ext/json/cJSON.h"
int luaopen_wax_json(lua_State *L);
