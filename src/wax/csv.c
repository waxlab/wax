/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/

#include <ceu/lua.h>
#include <ceu/array.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>


#define BUFFER_SIZE    1024
#define array_size(arr) (sizeof(arr)/sizeof((arr)[0]))


/*//////// DECLARATIONS ////////*/

int
luaopen_wax_csv_initc(lua_State *L);

Lua
wax_csv_open(lua_State *L),
wax_csv_close(lua_State *L),
wax_csv_lists(lua_State *L),
wax_csv_records(lua_State *L),
iter_lists(lua_State *L),
iter_records(lua_State *L);

LuaReg
module[] = {
  { "open",    wax_csv_open     },
  { "lists",   wax_csv_lists    },
  { "records", wax_csv_records  },
  { "close",   wax_csv_close    },
  { NULL,      NULL             }
};


/*//////// LUA USERDATA ////////*/

#define UD_CSV  "waxCsv"
struct ud_csv {
  /* File handler */
  const char *fname; /* file name                 */
  FILE *fp;           /* opened file from buffers are read */

  /* Atomic settings for char                     */
  char  sep;         /* value separator character */
  char  quo;         /* value quoting character   */
  char  chr;         /* last char parsed          */

  /* Temporary buffer for field extraction        */
  size_t valloc;     /* Allocated memory          */
  size_t vlen;       /* char count                */
  char  *val;        /* string                    */

  char **keys;       /* Lua keys or header fields */
  int     kisalloc;  /* are keys allocated?       */
  int     ended;
};

LuaReg
ud_csv_mt[] = {
  { "lists",   wax_csv_lists    },
  { "records", wax_csv_records  },
  { "close",   wax_csv_close    },
  { "__gc",    wax_csv_close    },
  #if LUA_VERSION_NUM >= 504
  { "__close", wax_csv_close    },
  #endif
  { NULL,      NULL             }
};


static int
aux_reset     (struct ud_csv *u),
aux_walk      (struct ud_csv *u, const char sep, const char quo),
aux_allockeys (struct ud_csv *u, size_t len);


static void
aux_resetkeys (struct ud_csv *u);

#define aux_nextchar(udcsv) ( \
  (fread(&udcsv->chr, 1, 1, udcsv->fp)) == 0 \
    ? (udcsv->chr = '\0') \
    : (udcsv->chr) \
)


/*//////// IMPLEMENTATION ////////*/

int
luaopen_wax_csv_initc(lua_State *L) {
  wLua_newuserdata_mt(L, UD_CSV, ud_csv_mt);
  wLua_export(L, module);
  return 1;
}


/* Create the handler for the CSV file */
Lua
wax_csv_open(lua_State *L) {
  struct ud_csv *u = lua_newuserdata(L, sizeof(*u));
  u->fname  = luaL_checkstring(L, 1);
  u->fp     = NULL;
  u->chr    = '\0';
  u->sep    = lua_isstring(L, 3) ? luaL_checkstring(L, 2)[0] : ',';
  u->quo    = lua_isstring(L, 2) ? luaL_checkstring(L, 3)[0] : '"';
  u->valloc = 0;
  u->vlen   = 0;
  u->val    = carray_new(u->val,1);
  u->keys   = NULL;
  u->ended  = 0;

  luaL_getmetatable(L, UD_CSV);
  lua_setmetatable(L, -2);

  return 1;
}


/* Close and release memory */
Lua
wax_csv_close(lua_State *L) {
  struct ud_csv *u = luaL_checkudata(L, 1, UD_CSV);

  if (u->fp == NULL && u->val == NULL) {
    lua_pushboolean(L, 0);
  } else {
    if (u->fp != NULL) {
      fclose(u->fp);
      u->fp = NULL;
    }

    carray_free(u->val);
    lua_pushboolean(L, 1);
  }
  return 1;
}


/* Lua generator for data as lists. Reset on each call */
Lua
wax_csv_lists(lua_State *L) {
  struct ud_csv *u = luaL_checkudata(L, 1, UD_CSV);
  wLua_assert(L, aux_reset(u), strerror(errno));
  aux_nextchar(u);
  lua_pushvalue(L,1);
  lua_pushcclosure(L, iter_lists, 1);
  return 1;
}


/* Iterator function used by wax.csv.lists */
Lua
iter_lists(lua_State *L) {
  struct ud_csv *u = lua_touserdata(L, lua_upvalueindex(1));

  if (u->chr == '\0') return 0;
  int idx = 1;
  int no_eor = 1;

  lua_newtable(L);

  do {
    no_eor = aux_walk(u, u->sep, u->quo);
    carray_push(u->val, '\0');
    wLua_pair_is(L, idx++, u->val);
  } while (no_eor);

  return 1;
}


/* Lua gen. for data as records. Reset on each call */
Lua
wax_csv_records(lua_State *L) {
  struct ud_csv *u = luaL_checkudata(L, 1, UD_CSV);
  wLua_assert(L, aux_reset(u),        strerror(errno));
  wLua_assert(L, aux_allockeys(u,2), strerror(errno));
  aux_nextchar(u);

  if (lua_gettop(L) < 2) { /* first row field as result key */

    int noeor;
    char *field;

    u->kisalloc = 1;
    if (u->chr == '\0') return 0;

    do {
      noeor = aux_walk(u, u->sep, u->quo);
      carray_push(u->val,'\0');
      field = carray_new(*field, carray_len(u->val));
      strcpy(field, u->val);
      wLua_assert(L, carray_push(u->keys, field), strerror(errno));
    } while(noeor);

  } else { /* table argument as result key */

    size_t k = 0;
    size_t l = 0;

    u->kisalloc = 0;
    luaL_argcheck(L, lua_istable(L,2), 2, "list of strings expected");
    lua_pushvalue(L,2);

    for (k=1, l=wLua_rawlen(L,-2); k <= l; k++) {
      lua_rawgeti(L,-1,k);
      wLua_assert(L, carray_push(u->keys, (char *)luaL_checkstring(L,-1)), strerror(errno));
      lua_pop(L,1);
    }
    lua_pop(L,1);

  }

  lua_pushvalue(L, 1);
  lua_pushcclosure(L, iter_records, 1);
  return 1;
}


/* Iterator function used by wax.csv.records */
Lua
iter_records(lua_State *L) {
  struct ud_csv *u = lua_touserdata(L, lua_upvalueindex(1));

  if (u->chr == '\0') return 0;

  int noeor;
  size_t k = 0;
  size_t l = carray_len(u->keys);

  lua_newtable(L);

  do {
    noeor = aux_walk(u, u->sep, u->quo);
    if (k < l) {
      carray_push(u->val, '\0');
      wLua_pair_ss(L, u->keys[k], u->val);
      k++;
    }
  } while (noeor);
  return 1;
}


/* Used to reset the file handler on wax.csv.records and wax.csv.lists */
static int
aux_reset(struct ud_csv *u) {
  if (u->fp != NULL) fclose(u->fp);
  if (u->keys != NULL) carray_free(u->keys);

  u->fp = fopen(u->fname, "r");
  if (u->fp == NULL) return 0;
  return 1;
}


static void
aux_resetkeys(struct ud_csv *u) {
  /* only free the string keys that came from CSV
   * ignoring the ones informed with Lua table as argument */
  if (u->kisalloc == 1) {

    size_t i = carray_len(u->keys);

    do { free(u->keys[--i]); } while(i>0);

  }
  carray_clear(u->keys);
}


static int
aux_allockeys(struct ud_csv *u, size_t len) {

  if (u->keys != NULL) {
    aux_resetkeys(u);
    return carray_capsz(u->keys, len);
  }

  u->keys = carray_new(u->keys, len);
  if (u->keys == NULL) return 0;
  return 1;
}


/* Returns:
 * 0 - when there is no field to be fetch on record
 * 1 - when still has fields to be fetched on the record (CSV row)
 */
static int
aux_walk(struct ud_csv *CSV, const char sep, const char quo) {
  char chr = CSV->chr;
  char *val = CSV->val;
  carray_clear(val);

  if (chr == quo ) goto get_quoted_value;
  if (chr == '\0') goto END_RECORD;

  simple_value:
    if (chr == sep ) goto SEP;
    if (chr == '\n') goto LF;
    if (chr == '\r') goto CR;
    if (chr == '\0') goto EOV; /* on loop is needed */
    carray_push(val,chr);
    chr = aux_nextchar(CSV);
    goto simple_value;

  get_quoted_value:
    chr = aux_nextchar(CSV);
    if (chr == '\0') goto END_RECORD;
    if (chr == quo && (chr = aux_nextchar(CSV)) != quo) goto find_delim;
    carray_push(val,chr);
    goto get_quoted_value;

  find_delim:
    if (chr == sep ) goto SEP;
    if (chr == '\n') goto LF;
    if (chr == '\r') goto CR;
    if (chr == '\0') goto END_RECORD;
    chr = aux_nextchar(CSV);
    goto find_delim;

  SEP:
    aux_nextchar(CSV);
    goto EOV;

  CR:
    if ((chr = aux_nextchar(CSV)) == '\n') aux_nextchar(CSV);
    goto END_RECORD;

  LF:
    aux_nextchar(CSV);
    goto END_RECORD;

  END_RECORD: /* Record ends with the this field */
    carray_push(val, '\0');
    CSV->val = &val[0];
    return 0;

  EOV: /* Field ends but not the record */
    carray_push(val, '\0');
    CSV->val = &val[0];
    return 1;
}

/* vim: set fdm=indent fdn=1 fen ts=2 sts=2 sw=2: */
