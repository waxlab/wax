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

#define BUFFER_SIZE   1024
#define LUADATA_NAME  "wax_csv_handler"
#define array_size(arr) (sizeof(arr)/sizeof((arr)[0]))



/* TYPES */

typedef struct csv_State {
  /* File handler */
  const char *fname; /* file name                         */
  const char *mode;  /* open() mode                       */
  FILE *fp;          /* opened file from buffers are read */

  /* Atomic settings for char */
  char  sep;         /* value separator character         */
  char  quo;         /* value quoting character           */
  char  chr;         /* last char parsed                  */

  /* Temporary buffer for field extraction */
  size_t bufalloc;   /* Allocated memory                  */
  size_t buflen;     /* char count                        */
  char  *bufval;     /* string                            */
} csv_State;

typedef enum { csv_val, csv_eor, csv_end } csv_Step;



/* LUA PUBLISHED FUNCTIONS */

static int wax_csv_open(lua_State *L);
static int wax_csv_close(lua_State *L);
static int wax_csv_irecords(lua_State *L);
static int iter_irecords(lua_State *L);

static const luaL_Reg csvh_mt[] = {
  { "irecords",   wax_csv_irecords },
  { "close",   wax_csv_close },
  { "__gc",    wax_csv_close },
  { "__close", wax_csv_close },
  { NULL,      NULL          }
};

static const luaL_Reg module[] = {
  { "open",  wax_csv_open  },
  { "close", wax_csv_close },
  { "irecords", wax_csv_irecords },
  { NULL,    NULL         }
};



/* PRIVATE FUNCTIONS & MACROS */

static int        csv_reset (csv_State *CSV, lua_State *L);
static csv_Step   csv_getval (csv_State *CSV);

static void       stradd (csv_State *CSV);
static void       strclr (csv_State *CSV);

#define is_quo(CSV) ((CSV)->chr == (CSV)->quo)
#define is_sep(CSV) ((CSV)->chr == (CSV)->sep)
#define is_eor(CSV) ((CSV)->chr == '\r' || (CSV)->chr == '\n')
#define is_eof(CSV) ((CSV)->chr == '\0')
#define nxtchr(CSV) if (fread(&CSV->chr, 1, 1, CSV->fp) == 0) CSV->chr = '\0'



/* ALGORITHM */

int luaopen_wax_csv(lua_State *L) {
  waxLua_newuserdata_mt(L, LUADATA_NAME, csvh_mt);
  waxLua_export(L, "wax_csv", module);
  return 1;
}



/* Create the handler for the CSV file */
static int wax_csv_open(lua_State *L) {
  csv_State *CSV = lua_newuserdata(L, sizeof(csv_State));
  CSV->fname    = luaL_checkstring(L, 1);
  CSV->mode     = luaL_checkstring(L, 2);
  CSV->fp       = NULL;
  CSV->chr      = '\0';
  CSV->sep      = lua_isstring(L, 3) ? luaL_checkstring(L, 3)[0] : ',';
  CSV->quo      = lua_isstring(L, 4) ? luaL_checkstring(L, 4)[0] : '"';
  CSV->bufalloc = 0;
  CSV->buflen   = 0;
  CSV->bufval   = NULL;

  luaL_getmetatable(L, LUADATA_NAME);
  lua_setmetatable(L, -2);

  return 1;
}

static int wax_csv_close(lua_State *L) {
  csv_State *CSV = luaL_checkudata(L, 1, LUADATA_NAME);

  if (CSV->fp == NULL && CSV->bufval == NULL)
    return 0;

  if (CSV->fp != NULL) {
    fclose(CSV->fp);
    CSV->fp = NULL;
  }
  if (CSV->bufval != NULL) {
    free(CSV->bufval);
    CSV->bufval = NULL;
  }

  lua_pushboolean(L, 1);
  return 1;
}


/*
 * Effectively open/reopen the file, so every time wax.cvs.irecords is used
 * the reading position is reset to the start of the file.
 */
static int wax_csv_irecords(lua_State *L) {
  csv_State *CSV = luaL_checkudata(L, 1, LUADATA_NAME);
  csv_reset(CSV, L);
  lua_pushcfunction(L, iter_irecords);
  lua_pushvalue(L, 1);
  return 2;
}


/* Iterators gets the record (a CSV line) values and left the cursor
 * at the first char of the next record
 */
static int iter_irecords(lua_State *L) {
  csv_State *CSV = luaL_checkudata(L, 1, LUADATA_NAME);

  if (is_eof(CSV)) return 0;

  int idx = 1;
  csv_Step S;

  lua_newtable(L);
  getval: {
    S = csv_getval(CSV);
    waxLua_pair_is(L, idx++, (CSV->bufval? CSV->bufval : ""));
    strclr(CSV);
    if (S == csv_val) goto getval;
  }

  return 1;
}


/* ------- C helpers ------- */

/* Really re/open the file and reset structure to 1st char */
static int csv_reset(csv_State *CSV, lua_State *L) {
  if (CSV->fp != NULL) fclose(CSV->fp);

  CSV->fp = fopen(CSV->fname, CSV->mode);
  waxLua_assert(L, CSV->fp != NULL, strerror(errno));

  nxtchr(CSV);
  return 1;
}




/* Read each field, char by char catenating to V->bufval.
 * When field ends, look for the next beginning and return csv_val
 * When row ends, look for the 1st char of next and return csv_eor.
 * when file ends (eof) can't go beyond so immediatelly return csv_eor.
 * The eof treatment should be done by the iterator.
 * */
static csv_Step csv_getval(csv_State *CSV) {
  if (is_quo(CSV)) goto fill_quoted;     /* Most common? */
  if (is_eof(CSV)) return csv_end;       /* Less common! */
  if (is_eor(CSV)) goto find_nextrecord; /* But need to discard EOF */

  fill: {
    if (is_sep(CSV)) {
      nxtchr(CSV);
      return csv_val;
    }

    if (is_eof(CSV)|| is_eor(CSV)) return csv_val;

    stradd(CSV);
    nxtchr(CSV);
    goto fill;
  }

  fill_quoted: {
    nxtchr(CSV);
    if (is_eof(CSV)) return csv_val;

    if (is_quo(CSV)) {
      nxtchr(CSV);

      if (!is_quo(CSV)) goto ignore;

      stradd(CSV);
      goto fill_quoted;
    }

    stradd(CSV);
    goto fill_quoted;
  }

  /* ignore anything between an ending quote and a separator */
  ignore: {
    if (is_sep(CSV)) {
      nxtchr(CSV);
      return csv_val;
    }
    if (is_eor(CSV)) goto find_nextrecord;
    if (is_eof(CSV)) return csv_val;
    goto ignore;
  }

  find_nextrecord: {
    nxtchr(CSV);
    if (!is_eor(CSV))
      return csv_eor;
    goto find_nextrecord;
  }

  return csv_end;
}


static void stradd(csv_State *CSV) {
  if (CSV->buflen+1 >= CSV->bufalloc) {
    CSV->bufalloc += BUFFER_SIZE;
    CSV->bufval = (char *) realloc(CSV->bufval, CSV->bufalloc);
  }
  CSV->bufval[CSV->buflen++] = CSV->chr;
  CSV->bufval[CSV->buflen] = '\0';
}


static void strclr(csv_State *CSV) {
  if (CSV->bufalloc > 0) {
    CSV->bufval[0] = '\0';
    CSV->buflen   = 0;
  }
}
