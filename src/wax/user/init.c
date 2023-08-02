/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <grp.h>
#include <pwd.h>
#include <ceu/lua.h>


/* //// DECLARATION //// */

int luaopen_wax_user_initc (lua_State *L);

Lua
wax_user_id     (lua_State *L),
wax_user_name   (lua_State *L),
wax_user_home   (lua_State *L),
wax_user_groups (lua_State *L),
wax_user_shell  (lua_State *L);


LuaReg module[] = {
  {"id",     wax_user_id     },
  {"name",   wax_user_name   },
  {"home",   wax_user_home   },
  {"groups", wax_user_groups },
  {"shell",  wax_user_shell  },
  {NULL, NULL}
};


/* //// IMPLEMENTATION //// */

int luaopen_wax_user_initc(lua_State *L) {
  wLua_export(L, module);
  return 1;
}

Lua
wax_user_id(lua_State *L) {
  if (!lua_gettop(L)) {
    lua_pushinteger(L, getuid());
    return 1;
  }

  struct passwd *p = getpwnam(luaL_checkstring(L,1));

  if (p == NULL) {
    lua_pushnil(L);
    return 1;
  }

  lua_pushinteger(L, p->pw_uid);
  return 1;
}

Lua
wax_user_name(lua_State *L) {
  int uid;
  if (lua_gettop(L)) {
    uid = luaL_checkinteger(L,1);
  } else {
    uid = getuid();
  }

  struct passwd *p = getpwuid(uid);

  if (p == NULL) {
    lua_pushnil(L);
    return 1;
  }

  lua_pushstring(L, p->pw_name);
  return 1;
}

Lua
wax_user_home(lua_State *L) {
  struct passwd *pw;

  if (! lua_gettop(L)) {
    pw = getpwuid(getuid());
  } else {
    if (lua_type(L,1) == LUA_TSTRING) {
      pw = getpwnam(luaL_checkstring(L,1));
    } else {
      pw = getpwuid(luaL_checkinteger(L,1));
    }
  }

  if (pw == NULL) {
    lua_pushnil(L);
    return 1;
  }

  lua_pushstring(L, pw->pw_dir);
  return 1;
}

Lua
wax_user_shell(lua_State *L) {
  struct passwd *pw;

  if (!lua_gettop(L)) {
    pw = getpwuid(getuid());
  } else {
    if (lua_type(L,1) == LUA_TSTRING) {
      pw = getpwnam(luaL_checkstring(L,1));
    } else {
      pw = getpwuid(luaL_checkinteger(L,1));
    }
  }

  if (pw == NULL) {
    lua_pushnil(L);
    return 1;
  }

  lua_pushstring(L, pw->pw_shell);
  return 1;
}

Lua
wax_user_groups(lua_State *L) {
  struct passwd *pw;

  if (!lua_gettop(L)) {
    pw = getpwuid(getuid());
  } else {
    if (lua_type(L,1) == LUA_TSTRING) {
      pw = getpwnam(luaL_checkstring(L,1));
    } else {
      pw = getpwuid(luaL_checkinteger(L,1));
    }
  }

  if (pw == NULL) {
    lua_pushnil(L);
    return 1;
  } else {
    int i, gnum = 1;
    gid_t *gids;
    if ((gids = realloc(NULL,sizeof(*gids) * gnum)) == NULL) {
      wLua_error(L, strerror(errno));
    }

    if (getgrouplist(pw->pw_name, pw->pw_gid, gids, &gnum) == -1) {
      gid_t *gids_2 = realloc(gids, sizeof(*gids) * gnum);
      if (!gids_2) {
        free(gids);
        wLua_error(L, strerror(errno));
      }
      gids = gids_2;
      getgrouplist(pw->pw_name, pw->pw_gid, gids, &gnum);
    }

    lua_createtable(L, gnum, 0);
    for (i = 1; i <= gnum; i++) {
      wLua_pair_ii(L, i, gids[i-1]);
    }
    free(gids);
    return 1;
  }
}


/* vim: set fdm=indent fdn=1 ts=2 sts=2 sw=2: */
