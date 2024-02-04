/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/
#include <ceu/lua.h>
#include <pthread.h>
#include <malloc.h>
#include <stdio.h>
// #include <ceu/array.h>

/* //// DECLARATION //// */
typedef struct funchunk {
  size_t  length;
  char   *data;
} funchunk;

int
luaopen_wax_async(lua_State *L);

Lua
wax_async_new(lua_State *L);


static inline int dump_writer (lua_State *L, const void* p, size_t sz, void* ud) {
  funchunk *dump = (funchunk *) ud;
  char *new = realloc( dump->data, sz + dump->length);
  if (new == NULL) {
    free(dump->data);
    lua_pushliteral(L, "Cannot allocate memory");
    return 1;
  }
  memcpy(new + dump->length, p, sz);
  dump->data = new;
  dump->length += sz;
  return 0;
}


static inline const
char *load_reader(lua_State *L, void *ud, size_t *sz) {
  funchunk *fc = (funchunk *) ud;
  if (fc->length == 0) {
    return NULL;
  }
  *sz = fc->length;
  fc->length = 0;
  return fc->data;
}


static inline
funchunk dump(lua_State *L) {
  funchunk fc = {
    .length = 0,
    .data = realloc(NULL, 1024)
  };

  #if LUA_VERSION_NUM >= 503
    lua_dump(L, dump_writer, &fc, 0);
  #else
    lua_dump(L, dump_writer, &fc);
  #endif
  return fc;
}


static inline
int load(lua_State *L, funchunk *fc, const char *fname) {
  #if LUA_VERSION_NUM >= 502
    return lua_load(L, load_reader, fc, fname, NULL);
  #else
    return lua_load(L, load_reader, fc, NULL);
  #endif
}


LuaReg module[] = {
  {"new", wax_async_new},
  { NULL, NULL         }
};

/* //// IMPLEMENTATION //// */

int luaopen_wax_async(lua_State *L) {
  wLua_export(L, module);
  return 1;
}

Lua
wax_async_new(lua_State *L) {
  if (!lua_isfunction(L, 1)) {
    lua_pushliteral(L, "Argument #1 must be a function");
    lua_error(L);
  }
  funchunk fc = dump(L);
  lua_State *S = luaL_newstate();
  int s = load(L, &fc, "somename");

//  lua_pushlstring(S, fc.data, fc.length);
//  lua_pushlstring(L, fc.data, fc.length);
//  lua_pushstring(L, fc.data);
  return 1;
}

