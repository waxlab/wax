/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/l8nab/wax)
 */

#include "c8l/l8n.h"
#include "c8l/arr.h"
#include <stddef.h>
#include <stdio.h>
#include "unistd.h"
#include "string.h"
#include "errno.h"

/* //// DECLARATION //// */


int
luaopen_wax_os(lua_State *L);

Lua
wax_os_exec(lua_State *L);

LuaReg
wax_os[] = {
	{"exec", wax_os_exec},
	{ NULL,  NULL       }
};

/* //// IMPLEMENTATION //// */

int
luaopen_wax_os(lua_State *L) {
	l8n_export(L, "wax.os", wax_os);
	return 1;
}

Lua
wax_os_exec(lua_State *L) {
	char **argv;
	size_t idx = 0;
	l8n_assert(L, (argv = c8l_arrnew(*argv,2)) != NULL, strerror(errno));
	c8l_arrpush(argv, (char *)luaL_checkstring(L,1));
	
	if (lua_istable(L, 2)) {
		for (idx=1; idx <= l8n_rawlen(L,2); idx++) {
			lua_rawgeti(L, 2, idx);
			c8l_arrpush(argv, (char *)luaL_checkstring(L, -1));
		}
	}
	c8l_arrpush(argv, NULL);
	execvp(argv[0], argv);
	c8l_arrfree(argv);

	return 0;
}


/* vim: set noet ts=2 sts=2 sw=2: */
