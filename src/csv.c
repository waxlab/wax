/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/waxlab/wax)
 */

#include "csv.h"
#include <stdlib.h>
#include <unistd.h>
#include "t8c/arr.h"

#define BUFFER_SIZE   1024
#define LUADATA_NAME  "wax_csv_handler"
#define array_size(arr) (sizeof(arr)/sizeof((arr)[0]))



/* TYPES */

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



/* LUA PUBLISHED FUNCTIONS */

static int wax_csv_open(lua_State *L);
static int wax_csv_close(lua_State *L);
static int wax_csv_lists(lua_State *L);
static int wax_csv_records(lua_State *L);
static int iter_lists(lua_State *L);
static int iter_records(lua_State *L);

static const luaL_Reg csvh_mt[] = {
  { "lists",   wax_csv_lists    },
  { "records", wax_csv_records  },
  { "close",   wax_csv_close    },
  { "__gc",    wax_csv_close    },
  { "__close", wax_csv_close    },
  { NULL,      NULL             }
};

static const luaL_Reg module[] = {
  { "open",    wax_csv_open     },
  { "lists",   wax_csv_lists    },
  { "records", wax_csv_records  },
  { "close",   wax_csv_close    },
  { NULL,      NULL             }
};



/* PRIVATE FUNCTIONS & MACROS */

static int        csv_reset  (CsvHandler *CSV, lua_State *L);
static int        csv_walk   (CsvHandler *CSV, const char sep, const char quo);


#define is_quo(CSV) ((CSV)->chr == (CSV)->quo)
#define is_sep(CSV) ((CSV)->chr == (CSV)->sep)
#define is_eor(CSV) ((CSV)->chr == '\r' || (CSV)->chr == '\n')
#define nextchar(CSV) (fread(&CSV->chr, 1, 1, CSV->fp)==0 ? (CSV->chr = '\0') : CSV->chr)



/* ALGORITHM */

int luaopen_wax_csv(lua_State *L) {
  waxL_newuserdata_mt(L, LUADATA_NAME, csvh_mt);
  waxL_export(L, "wax_csv", module);
  return 1;
}



/* Create the handler for the CSV file */
static int wax_csv_open(lua_State *L) {
  CsvHandler *CSV = lua_newuserdata(L, sizeof(CsvHandler));
  CSV->fname    = luaL_checkstring(L, 1);
  CSV->mode     = luaL_checkstring(L, 2);
  CSV->fp       = NULL;
  CSV->chr      = '\0';
  CSV->sep      = lua_isstring(L, 3) ? luaL_checkstring(L, 3)[0] : ',';
  CSV->quo      = lua_isstring(L, 4) ? luaL_checkstring(L, 4)[0] : '"';
  CSV->valloc   = 0;
  CSV->vlen     = 0;
  CSV->val      = t8c_arrnew(CSV->val,1);
  CSV->keys     = NULL;
  CSV->ended    = 0;

  luaL_getmetatable(L, LUADATA_NAME);
  lua_setmetatable(L, -2);

  return 1;
}


static int wax_csv_close(lua_State *L) {
  CsvHandler *CSV = luaL_checkudata(L, 1, LUADATA_NAME);

  if (CSV->fp == NULL && CSV->val == NULL)
    return 0;

  if (CSV->fp != NULL) {
    fclose(CSV->fp);
    CSV->fp = NULL;
  }

  t8c_arrfree(CSV->val);

  lua_pushboolean(L, 1);
  return 1;
}


/* Effectively open/reopen the file, so every time wax.cvs.lists is used
 * the reading position is reset to the start of the file.
 */
static int wax_csv_lists(lua_State *L) {
  CsvHandler *CSV = luaL_checkudata(L, 1, LUADATA_NAME);
  csv_reset(CSV, L);
  nextchar(CSV);
  lua_pushcfunction(L, iter_lists);
  lua_pushvalue(L, 1);
  return 2;
}


static int wax_csv_records(lua_State *L) {
  /*
  CsvHandler *CSV = luaL_checkudata(L, 1, LUADATA_NAME);
  nextchar(CSV);
  csv_reset(CSV, L);
  if (lua_istable(L,3)) {
    waxL_rawlen(L, 2);
  }
  lua_pushcfunction(L, iter_records);
  lua_pushvalue(L, 1);
  */
  return 2;
}


/* Get a CSV record as Lua indexed table.
 * left the cursor
 * at the first char of the next record
 */
static int iter_lists(lua_State *L) {
  CsvHandler *CSV = luaL_checkudata(L, 1, LUADATA_NAME);

  if (CSV->chr == '\0') return 0;
  register int idx = 1;
  register int no_eor = 1;

  lua_newtable(L);

  do {
    no_eor = csv_walk(CSV, CSV->sep, CSV->quo);
    t8c_arrpush(CSV->val,'\0');
    waxL_pair_is(L, idx++, CSV->val);
  } while (no_eor);

  return 1;
}


static int iter_records(lua_State *L) {
  return 0;
}

/* ------- C helpers ------- */

/* Really re/open the file and reset structure to 1st char */
static int csv_reset(CsvHandler *CSV, lua_State *L) {
  if (CSV->fp != NULL) fclose(CSV->fp);
  if (CSV->keys != NULL) t8c_arrfree(CSV->keys);

  CSV->fp = fopen(CSV->fname, CSV->mode);
  waxL_assert(L, CSV->fp != NULL, strerror(errno));
  return 1;
}



/* Returns:
 * 0 - when there is no field to be fetch on record
 * 1 - when still has fields to be fetched on the record (CSV row)
 */
static int csv_walk(CsvHandler *CSV, const char sep, const char quo) {

  register char chr = CSV->chr;
  char *val = CSV->val;
  t8c_arrclear(val);

  if (chr == quo ) goto get_quoted_value;
  if (chr == '\0') goto END_RECORD;

  simple_value:
    if (chr == sep ) goto SEP;
    if (chr == '\n') goto LF;
    if (chr == '\r') goto CR;
    if (chr == '\0') goto EOV; /* on loop is needed */
    t8c_arrpush(val,chr);
    chr = nextchar(CSV);
    goto simple_value;

  get_quoted_value:
    chr = nextchar(CSV);
    if (chr == '\0') goto END_RECORD;
    if (chr == quo && (chr = nextchar(CSV)) != quo) goto find_delim;
    t8c_arrpush(val,chr);
    goto get_quoted_value;

  find_delim:
    if (chr == sep ) goto SEP;
    if (chr == '\n') goto LF;
    if (chr == '\r') goto CR;
    if (chr == '\0') goto END_RECORD;
    chr = nextchar(CSV);
    goto find_delim;

  SEP:
    nextchar(CSV);
    goto EOV;

  CR:
    if ((chr = nextchar(CSV)) == '\n') nextchar(CSV);
    goto END_RECORD;

  LF:
    nextchar(CSV);
    goto END_RECORD;

  END_RECORD: /* Record ends with the this field */
    t8c_arrpush(val, '\0');
    CSV->val = &val[0];
    return 0;

  EOV: /* Field ends but not the record */
    t8c_arrpush(val, '\0');
    CSV->val = &val[0];
    return 1;
}

