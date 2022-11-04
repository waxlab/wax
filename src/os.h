/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/waxlab/wax)
 */

#include "wax.h"
#include <stddef.h>
#include <stdio.h>
#include "unistd.h"
#include "string.h"
#include "errno.h"


int luaopen_wax_os(lua_State *L);
