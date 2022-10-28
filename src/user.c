/*
** Wax
** A waxing Lua Standard Library
**
** Copyright (C) 2022 Thadeu A C de Paula
** (https://github.com/waxlab/wax)
*/


#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <grp.h>
#include <pwd.h>
#include "user.h"

static int wax_user_id(lua_State *L) {
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


static int wax_user_name(lua_State *L) {
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


static int wax_user_home(lua_State *L) {
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


static int wax_user_shell(lua_State *L) {
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


static int wax_user_groups(lua_State *L) {
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

  int gnum = 1;
  gid_t *gids = malloc(sizeof(*gids) * gnum);

  if (getgrouplist(pw->pw_name, pw->pw_gid, gids, &gnum) == -1) {
    gids = realloc(gids, sizeof(*gids) * gnum);
    getgrouplist(pw->pw_name, pw->pw_gid, gids, &gnum);
  }

  lua_createtable(L,gnum,0);
  for (int i=1; i <= gnum; i++) {
    waxLua_setfield_ii(L,i,gids[i-1]);
  }
  return 1;
}


static const luaL_Reg wax_user[] = {
  {"id",     wax_user_id     },
  {"name",   wax_user_name   },
  {"home",   wax_user_home   },
  {"groups", wax_user_groups },
  {"shell",  wax_user_shell  },
  {NULL, NULL}
};


int luaopen_wax_user(lua_State *L) {
  waxLua_export(L, "wax.user", wax_user);
  return 1;
}
