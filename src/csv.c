/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/w8lab/wax)
 */

#include "c8l/w8l.h"
#include "c8l/arr.h"
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>


#define BUFFER_SIZE    1024
#define CSV_DATANAME  "wax_csv_handler"
#define array_size(arr) (sizeof(arr)/sizeof((arr)[0]))


/*///////// DECLARATIONS /////////*/

int luaopen_wax_csv(lua_State *L);

typedef struct CsvHandler {
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
		{ "__gc",     wax_csv_close    },
		{ "__close", wax_csv_close    },
		{ NULL,       NULL             }
	},

	module[] = {
		{ "open",     wax_csv_open      },
		{ "lists",   wax_csv_lists    },
		{ "records", wax_csv_records  },
		{ "close",   wax_csv_close    },
		{ NULL,       NULL             }
	};


static int
	aux_reset      (CsvHandler *CSV),
	aux_walk      (CsvHandler *CSV, const char sep, const char quo),
	aux_allockeys (CsvHandler *CSV, size_t len);


static void
	aux_resetkeys (CsvHandler *CSV);


#define aux_nextchar(CSV) (              \
	(fread(&CSV->chr, 1, 1, CSV->fp)) == 0 \
		? (CSV->chr = '\0')                  \
		: (CSV->chr)                         \
)


/*/////////// IMPLEMENTATION ////////////*/

int luaopen_wax_csv(lua_State *L) {
	w8l_newuserdata_mt(L, CSV_DATANAME, csvh_mt);
	w8l_export(L, "wax_csv", module);
	return 1;
}


/* Create the handler for the CSV file */
Lua wax_csv_open(lua_State *L) {
	CsvHandler *CSV = lua_newuserdata(L, sizeof(CsvHandler));
	CSV->fname    = luaL_checkstring(L, 1);
	CSV->fp        = NULL;
	CSV->chr      = '\0';
	CSV->sep      = lua_isstring(L, 3) ? luaL_checkstring(L, 2)[0] : ',';
	CSV->quo      = lua_isstring(L, 2) ? luaL_checkstring(L, 3)[0] : '"';
	CSV->valloc    = 0;
	CSV->vlen      = 0;
	CSV->val      = c8l_arrnew(CSV->val,1);
	CSV->keys      = NULL;
	CSV->ended    = 0;

	luaL_getmetatable(L, CSV_DATANAME);
	lua_setmetatable(L, -2);

	return 1;
}


/* Close and release memory */
Lua wax_csv_close(lua_State *L) {
	CsvHandler *CSV = luaL_checkudata(L, 1, CSV_DATANAME);

	if (CSV->fp == NULL && CSV->val == NULL) {
		lua_pushboolean(L, 0);
	} else {
		if (CSV->fp != NULL) {
			fclose(CSV->fp);
			CSV->fp = NULL;
		}

		c8l_arrfree(CSV->val);
		lua_pushboolean(L, 1);
	}
	return 1;
}


/* Lua generator for data as lists. Reset on each call */
Lua wax_csv_lists(lua_State *L) {
	CsvHandler *CSV = luaL_checkudata(L, 1, CSV_DATANAME);
	w8l_assert(L, aux_reset(CSV), strerror(errno));
	aux_nextchar(CSV);
	lua_pushcfunction(L, iter_lists);
	lua_pushvalue(L, 1);
	return 2;
}


/* Iterator function used by wax.csv.lists */
Lua iter_lists(lua_State *L) {
	CsvHandler *CSV = luaL_checkudata(L, 1, CSV_DATANAME);

	if (CSV->chr == '\0') return 0;
	register int idx = 1;
	register int no_eor = 1;

	lua_newtable(L);

	do {
		no_eor = aux_walk(CSV, CSV->sep, CSV->quo);
		c8l_arrpush(CSV->val, '\0');
		w8l_pair_is(L, idx++, CSV->val);
	} while (no_eor);

	return 1;
}


/* Lua gen. for data as records. Reset on each call */
Lua wax_csv_records(lua_State *L) {
	CsvHandler *CSV = luaL_checkudata(L, 1, CSV_DATANAME);
	w8l_assert(L, aux_reset(CSV),        strerror(errno));
	w8l_assert(L, aux_allockeys(CSV,2), strerror(errno));
	aux_nextchar(CSV);

	if (lua_gettop(L) < 2) { /* first row field as result key */

		register int noeor;
		char *field;

		CSV->kisalloc = 1;
		if (CSV->chr == '\0') return 0;

		do {
			noeor = aux_walk(CSV, CSV->sep, CSV->quo);
			c8l_arrpush(CSV->val,'\0');
			field = c8l_arrnew(*field, c8l_arrlen(CSV->val));
			strcpy(field, CSV->val);
			w8l_assert(L, c8l_arrpush(CSV->keys, field), strerror(errno));
		} while(noeor);

	} else { /* table argument as result key */

		register size_t k = 0;
		register size_t l = 0;

		CSV->kisalloc = 0;
		luaL_argcheck(L, lua_istable(L,2), 2, "list of strings expected");
		lua_pushvalue(L,2);

		for (k=1, l=w8l_rawlen(L,-2); k <= l; k++) {
			lua_rawgeti(L,-1,k);
			w8l_assert(L, c8l_arrpush(CSV->keys, (char *)luaL_checkstring(L,-1)), strerror(errno));
			lua_pop(L,1);
		}
		lua_pop(L,1);

	}

	lua_pushcfunction(L, iter_records);
	lua_pushvalue(L, 1);
	return 2;
}


/* Iterator function used by wax.csv.records */
Lua iter_records(lua_State *L) {
	CsvHandler *CSV = luaL_checkudata(L, 1, CSV_DATANAME);

	if (CSV->chr == '\0') return 0;

	register int noeor;
	register size_t k = 0,
	                l = c8l_arrlen(CSV->keys);

	lua_newtable(L);

	do {
		noeor = aux_walk(CSV, CSV->sep, CSV->quo);
		if (k < l) {
			c8l_arrpush(CSV->val, '\0');
			w8l_pair_ss(L, CSV->keys[k], CSV->val);
			k++;
		}
	} while (noeor);
	return 1;
}


/* Used to reset the file handler on wax.csv.records and wax.csv.lists */
static int aux_reset(CsvHandler *CSV) {
	if (CSV->fp != NULL) fclose(CSV->fp);
	if (CSV->keys != NULL) c8l_arrfree(CSV->keys);

	CSV->fp = fopen(CSV->fname, "r");
	if (CSV->fp == NULL) return 0;
	return 1;
}


static void aux_resetkeys(CsvHandler *CSV) {
	/* only free the string keys that came from CSV
	 * ignoring the ones informed with Lua table as argument */
	if (CSV->kisalloc == 1) {

		register size_t i = c8l_arrlen(CSV->keys);

		do { free(CSV->keys[--i]); } while(i>0);

	}
	c8l_arrclear(CSV->keys);
}


static int aux_allockeys(CsvHandler *CSV, size_t len) {

	if (CSV->keys != NULL) {
		aux_resetkeys(CSV);
		return c8l_arrcapsz(CSV->keys, len);
	}

	CSV->keys = c8l_arrnew(CSV->keys, len);
	if (CSV->keys == NULL) return 0;
	return 1;
}


/* Returns:
 * 0 - when there is no field to be fetch on record
 * 1 - when still has fields to be fetched on the record (CSV row)
 */
static int aux_walk(CsvHandler *CSV, const char sep, const char quo) {
	register char chr = CSV->chr;
	char *val = CSV->val;
	c8l_arrclear(val);

	if (chr == quo ) goto get_quoted_value;
	if (chr == '\0') goto END_RECORD;

	simple_value:
		if (chr == sep ) goto SEP;
		if (chr == '\n') goto LF;
		if (chr == '\r') goto CR;
		if (chr == '\0') goto EOV; /* on loop is needed */
		c8l_arrpush(val,chr);
		chr = aux_nextchar(CSV);
		goto simple_value;

	get_quoted_value:
		chr = aux_nextchar(CSV);
		if (chr == '\0') goto END_RECORD;
		if (chr == quo && (chr = aux_nextchar(CSV)) != quo) goto find_delim;
		c8l_arrpush(val,chr);
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
		c8l_arrpush(val, '\0');
		CSV->val = &val[0];
		return 0;

	EOV: /* Field ends but not the record */
		c8l_arrpush(val, '\0');
		CSV->val = &val[0];
		return 1;
}

/* vim: set fdm=indent fdn=1 fen ts=2 sts=2 sw=2: */
