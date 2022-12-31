/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/w8lab/wax)
 */

#include "w8l/w8l.h"
#include "t8l/arr.h"
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>


#define BUFFER_SIZE   1024
#define LUADATA_NAME  "wax_csv_handler"
#define array_size(arr) (sizeof(arr)/sizeof((arr)[0]))


/*///////// DECLARATIONS /////////*/

int luaopen_wax_csv(lua_State *L);

typedef struct CsvHandler {
  /* File handler */
  const char *fname; /* file name                         */
  const char *mode;  /* open() mode                       */
  FILE *fp;          /* opened file from buffers are read */

  /* Atomic settings for char */
  char  sep;         /* value separator character         */
  char  quo;         /* value quoting character           */
  char  chr;         /* last char parsed                  */

  /* Temporary buffer for field extraction */
  size_t valloc;     /* Allocated memory                  */
  size_t vlen;       /* char count                        */
  char  *val;        /* string                            */

  char **keys;       /* Lua keys or CSV head field names  */
  int    ended;
} CsvHandler;

typedef enum { csv_val, csv_eor, csv_end } CsvStep;


Lua
  wax_csv_open(lua_State *L),
  wax_csv_close(lua_State *L),
  wax_csv_lists(lua_State *L),
  wax_csv_records(lua_State *L),

  iter_lists(lua_State *L),
  iter_records(lua_State *L);

LuaReg
  csvh_mt[] = {
    { "lists",   wax_csv_lists    },
    { "records", wax_csv_records  },
    { "close",   wax_csv_close    },
    { "__gc",    wax_csv_close    },
    { "__close", wax_csv_close    },
    { NULL,      NULL             }
  },

  module[] = {
    { "open",    wax_csv_open     },
    { "lists",   wax_csv_lists    },
    { "records", wax_csv_records  },
    { "close",   wax_csv_close    },
    { NULL,      NULL             }
  };


static int
  aux_reset  (CsvHandler *CSV),
  aux_walk   (CsvHandler *CSV, const char sep, const char quo);


#define aux_nextchar(CSV) (                  \
  (fread(&CSV->chr, 1, 1, CSV->fp)) == 0 \
    ? (CSV->chr = '\0')                  \
    : (CSV->chr)                         \
)


/*/////////// IMPLEMENTATION ////////////*/

int luaopen_wax_csv(lua_State *L) {
  w8l_newuserdata_mt(L, LUADATA_NAME, csvh_mt);
  w8l_export(L, "wax_csv", module);
  return 1;
}

/* Create the handler for the CSV file */
Lua wax_csv_open(lua_State *L) {
  CsvHandler *CSV = lua_newuserdata(L, sizeof(CsvHandler));
  CSV->fname    = luaL_checkstring(L, 1);
  CSV->mode     = luaL_checkstring(L, 2);
  CSV->fp       = NULL;
  CSV->chr      = '\0';
  CSV->sep      = lua_isstring(L, 3) ? luaL_checkstring(L, 3)[0] : ',';
  CSV->quo      = lua_isstring(L, 4) ? luaL_checkstring(L, 4)[0] : '"';
  CSV->valloc   = 0;
  CSV->vlen     = 0;
  CSV->val      = t8l_arrnew(CSV->val,1);
  CSV->keys     = NULL;
  CSV->ended    = 0;

  luaL_getmetatable(L, LUADATA_NAME);
  lua_setmetatable(L, -2);

  return 1;
}

/* Close and release memory */
Lua wax_csv_close(lua_State *L) {
  CsvHandler *CSV = luaL_checkudata(L, 1, LUADATA_NAME);

  if (CSV->fp == NULL && CSV->val == NULL)
    return 0;

  if (CSV->fp != NULL) {
    fclose(CSV->fp);
    CSV->fp = NULL;
  }

  t8l_arrfree(CSV->val);

  lua_pushboolean(L, 1);
  return 1;
}


/* Lua generator for data as lists. Reset on each call */
Lua wax_csv_lists(lua_State *L) {
  CsvHandler *CSV = luaL_checkudata(L, 1, LUADATA_NAME);
  w8l_assert(L, aux_reset(CSV), strerror(errno));
  aux_nextchar(CSV);
  lua_pushcfunction(L, iter_lists);
  lua_pushvalue(L, 1);
  return 2;
}

/* Iterator function used by wax.csv.lists */
Lua iter_lists(lua_State *L) {
  CsvHandler *CSV = luaL_checkudata(L, 1, LUADATA_NAME);

  if (CSV->chr == '\0') return 0;
  register int idx = 1;
  register int no_eor = 1;

  lua_newtable(L);

  do {
    no_eor = aux_walk(CSV, CSV->sep, CSV->quo);
    t8l_arrpush(CSV->val,'\0');
    w8l_pair_is(L, idx++, CSV->val);
  } while (no_eor);

  return 1;
}

/* Lua gen. for data as records. Reset on each call */
Lua wax_csv_records(lua_State *L) {
  /*
  CsvHandler *CSV = luaL_checkudata(L, 1, LUADATA_NAME);
  aux_nextchar(CSV);
  aux_reset(CSV, L);
  if (lua_istable(L,3)) {
    w8l_rawlen(L, 2);
  }
  lua_pushcfunction(L, iter_records);
  lua_pushvalue(L, 1);
  */
  return 2;
}

/* Iterator function used by wax.csv.records */
Lua iter_records(lua_State *L) {
  return 0;
}

/* Used to reset the file handler on wax.csv.records and wax.csv.lists */
static int aux_reset(CsvHandler *CSV) {
  if (CSV->fp != NULL) fclose(CSV->fp);
  if (CSV->keys != NULL) t8l_arrfree(CSV->keys);

  CSV->fp = fopen(CSV->fname, CSV->mode);
  if (CSV->fp == NULL) return 0;
  return 1;
}



/* Returns:
 * 0 - when there is no field to be fetch on record
 * 1 - when still has fields to be fetched on the record (CSV row)
 */
static int aux_walk(CsvHandler *CSV, const char sep, const char quo) {
  register char chr = CSV->chr;
  char *val = CSV->val;
  t8l_arrclear(val);

  if (chr == quo ) goto get_quoted_value;
  if (chr == '\0') goto END_RECORD;

  simple_value:
    if (chr == sep ) goto SEP;
    if (chr == '\n') goto LF;
    if (chr == '\r') goto CR;
    if (chr == '\0') goto EOV; /* on loop is needed */
    t8l_arrpush(val,chr);
    chr = aux_nextchar(CSV);
    goto simple_value;

  get_quoted_value:
    chr = aux_nextchar(CSV);
    if (chr == '\0') goto END_RECORD;
    if (chr == quo && (chr = aux_nextchar(CSV)) != quo) goto find_delim;
    t8l_arrpush(val,chr);
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
    t8l_arrpush(val, '\0');
    CSV->val = &val[0];
    return 0;

  EOV: /* Field ends but not the record */
    t8l_arrpush(val, '\0');
    CSV->val = &val[0];
    return 1;
}

/* vim: set fdm=indent fdn=1 ts=2 sts=2 sw=2: */
