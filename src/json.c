/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/w8lab/wax)
 */

#include "c8l/w8l.h"
#include <stdlib.h>    /* realpath */
#include <stdio.h>
#include <string.h>
#include "lua.h"

#define  CJSON_NESTING_LIMIT INT_MAX
#include "ext/json/cJSON.h"



/* ///////// DECLARATION ///////// */

typedef struct { int used; int limit; } stack_s;


int luaopen_wax_json(lua_State *L);

Lua
	wax_json_decode(lua_State *L),
	wax_json_encode(lua_State *L);

static void
	aux_luastack_alloc(lua_State *L, stack_s *stack, int size),
	aux_decode(lua_State *L, cJSON *val, stack_s *S),
	aux_decobj(lua_State *L, cJSON *node, stack_s *stack, int len),
	aux_decarr(lua_State *L, cJSON *node, stack_s *stack, int len);

static cJSON
	*aux_encode    (lua_State*, stack_s*),
	*aux_enc_tdict (lua_State*, stack_s*),
	*aux_enc_tlist (lua_State*, stack_s*, int);

static int json_null_userdata = 0;

LuaReg wax_json[] = {
	{ "decode",     wax_json_decode },
	{ "encode",     wax_json_encode },
	{ NULL,         NULL            }
};


int luaopen_wax_json(lua_State *L) {
	w8l_export(L, "wax.json", wax_json);
	lua_pushlightuserdata(L, (void *) &json_null_userdata);
	lua_setfield(L,-2, "null");
	return 1;
}

#define aux_pushnumber(L,j) \
	if ((j)->valuedouble>(j->valueint)) { \
		lua_pushnumber((L),(j->valuedouble)); \
	} else { \
		lua_pushinteger((L),(j->valueint));\
	};

#define aux_pushludata(L,d) lua_pushlightuserdata((L),(void *)&(d));



/* ///////// IMPLEMENTATION ///////// */


/* ---- Decode ---- */

Lua wax_json_decode(lua_State *L) {
	cJSON *json   = cJSON_Parse(luaL_checkstring(L, 1));
	stack_s stack = { 0, LUA_MINSTACK };
	stack.used    = lua_gettop(L);
	aux_decode(L, json, &stack);
	cJSON_Delete(json);
	return 1;
}


static void aux_decode(lua_State *L, cJSON *val, stack_s *S) {
	if ( cJSON_IsObject(val) ) {
		aux_decobj(L, val->child, S, cJSON_GetArraySize(val));
	} else if ( cJSON_IsArray(val) ) {
		aux_decarr(L, val->child, S, cJSON_GetArraySize(val));
	} else if ( cJSON_IsString(val) ) {
		lua_pushstring  (L, val->valuestring);
	} else if ( cJSON_IsNumber(val) ) {
		aux_pushnumber(L, val);
	} else if ( cJSON_IsBool(val) ) {
		lua_pushboolean(L, val->valueint);
	} else if ( cJSON_IsNull(val) ) {
		aux_pushludata(L, json_null_userdata);
	}
}


static void aux_decobj(lua_State *L, cJSON *node, stack_s *stack, int len) {
	int i;
	aux_luastack_alloc(L, stack, 2);
	lua_createtable(L,0,len);
	for (i=0; i < len; i++) {
		lua_pushstring(L, node->string); /* The object key */
		aux_decode(L, node, stack);
		lua_settable(L,-3);
		node = node->next;
	}
	aux_luastack_alloc(L, stack, -2);
}


static void aux_decarr(lua_State *L, cJSON *node, stack_s *stack, int len) {
	int i;
	aux_luastack_alloc(L, stack, 2);
	lua_createtable(L,len,0);
	for (i=1; i <= len; i++) {
		lua_pushinteger(L, i); /* The object key */
		aux_decode(L, node, stack);
		lua_settable(L,-3);
		node = node->next;
	}
	aux_luastack_alloc(L, stack, -2);
}

/* ---- Encode ---- */

Lua wax_json_encode(lua_State *L) {
	cJSON *res;
	stack_s stack = { 0, LUA_MINSTACK };

	lua_pushvalue(L, 1);
	if ((res = aux_encode(L, &stack)) != NULL) {
		lua_pushstring(L,cJSON_PrintUnformatted(res));
		cJSON_Delete(res);
		return 1;
	}

	lua_error(L);
	return 0;
}


static cJSON *aux_encode(lua_State *L, stack_s *S) {
	switch( lua_type(L, -1) ) {
		case LUA_TTABLE: {
			int len;
			if ((len = w8l_rawlen(L,-1)) > 0)
				return aux_enc_tlist(L, S, len);
			return aux_enc_tdict(L, S);
		}

		case LUA_TNUMBER:
			return cJSON_CreateNumber(lua_tonumber(L, -1));

		case LUA_TSTRING:
			return cJSON_CreateString(lua_tostring(L, -1));

		case LUA_TBOOLEAN:
			return cJSON_CreateBool(lua_toboolean(L, -1));

		case LUA_TLIGHTUSERDATA:
			if (lua_touserdata(L, -1) == &json_null_userdata)
				return cJSON_CreateNull();

			lua_pushstring(L, "Invalid lightuserdata found");
			return NULL;

		default:
			lua_pushstring(L, "Invalid table values");
			lua_error(L);
	}
	return NULL;
}


static cJSON *aux_enc_tlist(lua_State *L, stack_s *S, int len) {
	int i   = 0,
	    idx = lua_gettop(L);

	cJSON *val,
		    *array = cJSON_CreateArray();
	aux_luastack_alloc(L,S,2);
	for (i=1; i <= len; i++) {
		lua_rawgeti(L,idx,i);
		if ((val = aux_encode(L, S)) == NULL) goto fail;
		cJSON_AddItemToArray(array, val);
		lua_pop(L,1);
	}

	/* success: */
	aux_luastack_alloc(L,S,-2);
	return array;
	
	fail:
		lua_pop(L,1);
		aux_luastack_alloc(L,S,-2);
		cJSON_Delete(array);
		return NULL;
}


static cJSON *aux_enc_tdict(lua_State *L, stack_s *S) {
	cJSON *val, *obj;
	int idx = lua_gettop(L);
	aux_luastack_alloc(L,S,2);
	lua_pushnil(L);
	obj = cJSON_CreateObject();
	while (lua_next(L, idx) != 0) {
		if (lua_type(L,-2) == LUA_TSTRING) {
			if ((val = aux_encode(L, S)) == NULL) goto fail;
			cJSON_AddItemToObject(obj, lua_tostring(L,-2), val);
		} else {
			lua_pushstring(L,"No string key found on table");
			goto fail;
		}
		lua_pop(L,1);
	}
	aux_luastack_alloc(L,S,-2);
	return obj;

	fail :
		if (obj != NULL) cJSON_Delete(obj);
		return NULL;
}


/* ---- Stack allocation ---- */

static void aux_luastack_alloc(lua_State *L, stack_s *stack, int size) {
	stack->used += size;
	if ( stack->used > stack->limit ) {
		if (lua_checkstack(L, (stack->limit += size)) != 1) {
			lua_pushstring(L,"Cannot allocate space for Lua stack");
			lua_error(L);
		}
	}
	return;
}


/* vim: set fdm=indent fdn=1 ts=2 sts=2 sw=2: */
