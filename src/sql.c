/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/waxlab/wax)
 */

#include "c8l/l8n.h"
#include "c8l/arr.h"
#include <sqlite3.h>
#include <math.h>


/*//////// DECLARATIONS ////////*/

#define is_int(n) (((n) - floor(n)) == 0)

#define bindvalues(S,L) ((S)->btype == STMT_PNAME \
                       ? bindnames((S),(L)) \
                       : bindpos((S),(L)))

#define CONCHECK(L,D) if ((D)->conn == NULL) {\
	lua_pushnil((L));                           \
	lua_pushstring((L), "closed connection");   \
	return 2;                                   \
}

#define STMTCHECK(L,S) if ((S)->S == NULL) {  \
	lua_pushnil((L));                           \
	lua_pushstring((L), "finalized statement"); \
	return 2;                                   \
}

typedef struct waxSql {
	sqlite3 *conn;
} waxSql;


/* Describes a statement bind/ing strategy: anonymous our named */


typedef struct waxSqlStmt {
	sqlite3_stmt  *S;
	int           cols;
	const char    *err;

	enum bindtype { STMT_PNAME, STMT_PANON, } btype;
	union {
		int
			bpos;
		const char
			**bnames;
	};
} waxSqlStmt;


int
luaopen_wax_sql(lua_State *L);

Lua
wax_sql_open    (lua_State *L),
wax_sql_close   (lua_State *L),
wax_sql_exec    (lua_State *L),
wax_sql_prep    (lua_State *L),
wax_sql_run     (lua_State *L),
wax_sql_fetch   (lua_State *L),
wax_sql_fetchok (lua_State *L),
wax_sql_final   (lua_State *L),
wax_sql_version (lua_State *L),
iter_fetch      (lua_State *L);

static int
bindnames       (waxSqlStmt *S, lua_State *L),
bindpos         (waxSqlStmt *S, lua_State *L);

static char
*sqltrim        (const char *i, int *trimmed);




static int wax_sql_null = 0;

LuaReg module[] = {
	{"open",    wax_sql_open   },
	{"close",   wax_sql_close  },
	{"prepare", wax_sql_prep   },
	{"execute", wax_sql_exec   },
	{"fetch",   wax_sql_fetch  },
	{"fetchok", wax_sql_fetchok},
	{"run",     wax_sql_run    },
	{"version", wax_sql_version},
	{ NULL,     NULL           },
};

/*//////// LUA USERDATA ////////*/

#define UD_SQL "waxSql"
LuaReg wax_sql_mt[] = {
	{ "execute", wax_sql_exec  },
	{ "prepare", wax_sql_prep  },
	{ "close",   wax_sql_close },
	{ "_gc",     wax_sql_close },
	#if LUA_VERSION_NUM >= 504
	{ "_close",  wax_sql_close },
	#endif
	{ NULL,      NULL },
};


#define UD_SQL_STMT "waxSqlStmt"
LuaReg wax_sql_stmtmt[] = {
	{ "fetch",   wax_sql_fetch  },
	{ "fetchok", wax_sql_fetchok},
	{ "run",     wax_sql_run    },
	{ "finalize",wax_sql_final  },
	{ "_gc",     wax_sql_final  },
	#if LUA_VERSION_NUM >= 504
	{ "_close",  wax_sql_final  },
	#endif
	{ NULL,      NULL },
};


#define is_name_param(n) ( (n) != NULL && (n)[0] != '?' )


/*//////// IMPLEMENTATION ////////*/


int luaopen_wax_sql(lua_State *L) {
	l8n_newuserdata_mt(L, UD_SQL,      wax_sql_mt);
	l8n_newuserdata_mt(L, UD_SQL_STMT, wax_sql_stmtmt);
	l8n_export(L, "wax_sql", module);
	
	lua_pushlightuserdata(L, (void *) &wax_sql_null);
	lua_setfield(L,-2,"null");
	return 1;
}


Lua
wax_sql_open(lua_State *L) {
	waxSql *D = lua_newuserdata(L, sizeof(*D));
	int rc = sqlite3_open(luaL_checkstring(L,1), &(D->conn));

	if (SQLITE_OK == rc) {
		luaL_getmetatable(L,UD_SQL);
		lua_setmetatable(L,-2);
		return 1;
	}
	lua_pushnil(L);
	lua_pushstring(L, sqlite3_errmsg(D->conn));
	sqlite3_close(D->conn);
	return 2;
}


Lua
wax_sql_close(lua_State *L) {
	waxSql *D = luaL_checkudata(L, 1, UD_SQL);

	if (D->conn == NULL) {
		lua_pushboolean(L,0);
	} else {
		sqlite3_close(D->conn);
		D->conn = NULL;
		lua_pushboolean(L,1);
	}
	return 1;
}


/*
 * Just execute statement without check or bind values
 */
Lua
wax_sql_exec(lua_State *L) {
	/* waxSqlStmt unneeded for internal function usage */
	waxSql       *D  = luaL_checkudata(L, 1, UD_SQL);
	sqlite3_stmt *S;
	CONCHECK(L, D);
	int rc;

	int trimmed;
	int qnum = 0;
	char *sql = sqltrim(luaL_checkstring(L,2), &trimmed);
	void *p_sql;

	if (trimmed == -1) goto cError;
	if (trimmed ==  1) p_sql = &sql[0];
	
	while(sql[0] != '\0') {
		qnum++;
		rc = sqlite3_prepare_v2(D->conn, sql, -1, &S, (const char **) &sql);
	
		if (SQLITE_OK   != rc) goto sqlError;
	
		while(SQLITE_ROW == (rc = sqlite3_step(S)));
		if (SQLITE_DONE != rc) goto sqlError;
		
		sqlite3_finalize(S);
		if (SQLITE_DONE != rc) goto sqlError;
	}

	if (SQLITE_DONE == rc) { /* success */
		lua_pushboolean(L, 1);
		if (trimmed == 1) free(p_sql);
		return 1;
	}

	cError:
		lua_pushnil(L);
		lua_pushfstring(L, strerror(errno));
		return 2;

	sqlError:
		sqlite3_finalize(S);
		lua_pushnil(L);
		lua_pushfstring(L, "statement #%d %s", qnum, rc == 1
		                                      ? sqlite3_errmsg(D->conn)
		                                      : sqlite3_errstr(rc) );
		if (trimmed == 1) free(p_sql);
		return 2;
}

Lua
wax_sql_prep(lua_State *L) {
	int i = 1;
	int bpos;
	const char *sql = luaL_checkstring(L, 2);
	waxSql     *D   = luaL_checkudata(L, 1, UD_SQL);
	waxSqlStmt *S   = lua_newuserdata(L, sizeof(*S));
	CONCHECK(L, D);
	S->err = NULL;

	if (SQLITE_OK != sqlite3_prepare_v2(D->conn, sql, -1, &S->S, NULL))
		goto Error;

	bpos = sqlite3_bind_parameter_count(S->S);
	const char *name = bpos > 0 ? sqlite3_bind_parameter_name(S->S, i)
	                              : NULL;

	if (is_name_param(name)) {

		S->bnames = c8l_arrnew(*S->bnames, 4);
		c8l_arrpush(S->bnames, (const char *) &name[1]);

		for (i=2; i <= bpos; i++) {
			name = sqlite3_bind_parameter_name(S->S, i);
			l8n_assert(L,is_name_param(name), "Mixes named and unamed parameters");
			l8n_assert(L,
			           c8l_arrpush(S->bnames, (const char *) &name[1]),
			           strerror(errno));
		}
		
		S->btype = STMT_PNAME;

	} else {

		for (i=1; i <= bpos; i++) {
			name = sqlite3_bind_parameter_name(S->S, i);
			l8n_assert(L, !is_name_param(name), "Mixes unamed and named parameters");
		}

		S->btype = STMT_PANON;
		S->bpos = bpos;

	}
	S->cols = -1;
	luaL_getmetatable(L,UD_SQL_STMT);
	lua_setmetatable(L,-2);
	return 1;

	Error:
		lua_pushnil(L);
		lua_pushstring(L, sqlite3_errmsg(D->conn));
		return 2;
}


Lua
wax_sql_final(lua_State *L) {
	waxSqlStmt *S = luaL_checkudata(L, 1, UD_SQL_STMT);
	if (S->S != NULL) {
		if (S->btype == STMT_PNAME) c8l_arrclear(S->bnames);
		int rc = sqlite3_finalize(S->S);
		S->S = NULL;
		if (SQLITE_OK == rc) {
			lua_pushboolean(L,1);
			return 1;
		}
		lua_pushnil(L);
		lua_pushstring(L, sqlite3_errstr(rc));
		return 2;
	} else {
		lua_pushnil(L);
		lua_pushstring(L, "statement already closed");
		return 2;
	}
}


Lua
wax_sql_run(lua_State *L) {
	waxSqlStmt *S = luaL_checkudata(L, 1, UD_SQL_STMT);
	STMTCHECK(L,S);
	int rc;
	
	if    (SQLITE_OK   != (rc = sqlite3_reset(S->S))) goto Error;
	if    (SQLITE_OK   != (rc = bindvalues(S, L)))    goto Error;
	while (SQLITE_ROW  == (rc = sqlite3_step(S->S)))  {};
	if    (SQLITE_DONE != rc)                         goto Error;
	lua_pushinteger(L,sqlite3_changes(sqlite3_db_handle(S->S)));
	return 1;

	Error:
		lua_pushnil(L);
		lua_pushstring(L, rc == 1 ? sqlite3_errmsg(sqlite3_db_handle(S->S))
		                          : sqlite3_errstr(rc));
		return 2;
}


/*
 * Actually it is the binder function that returns the
 * userdata and the iterator to run the steps
 */
Lua
wax_sql_fetch(lua_State *L) {
	waxSqlStmt *S = luaL_checkudata(L, 1, UD_SQL_STMT);
	int rc;
	STMTCHECK(L,S);

	if (S->cols < 0)
		S->cols = sqlite3_column_count(S->S);
	
	if (SQLITE_OK != (rc=sqlite3_reset(S->S)) || SQLITE_OK != (rc=bindvalues(S, L))) {
		S->err = sqlite3_errstr(rc);
		return 0;
	} else {
		S->err = "unstarted";
		lua_pushvalue(L,1);
		lua_pushcclosure(L, iter_fetch,1);
		return 1;
	}
}


Lua
iter_fetch(lua_State *L) {
	waxSqlStmt *S = lua_touserdata(L, lua_upvalueindex(1));
	int c = S->cols;
	int rc;
	if (!c) return 0;

	rc = sqlite3_step(S->S);
	if (SQLITE_ROW == rc) {
		S->err = "pending";
		lua_newtable(L);
		for (; --c >= 0 ;) switch(sqlite3_column_type(S->S, c)) {
			case SQLITE_INTEGER:
				l8n_pair_si(L,
				            sqlite3_column_name(S->S,c),
				            sqlite3_column_int(S->S, c));
				break;
			case SQLITE_FLOAT:
				l8n_pair_sn(L,
				            sqlite3_column_name(S->S,c),
				            sqlite3_column_double(S->S, c));
				break;
			case SQLITE_NULL:
				l8n_pair_slu(L,
				             sqlite3_column_name(S->S,c),
				             &(wax_sql_null));
				break;
			default: /* for blob, text and others */
				l8n_pair_ss(L,
				            sqlite3_column_name(S->S,c),
				            (const char *) sqlite3_column_text(S->S, c));
				rc = 1;
		}
		return 1;
	}
	S->err = SQLITE_DONE == rc ? NULL : sqlite3_errstr(rc);
	return 0;
}


Lua
wax_sql_fetchok(lua_State *L) {
	waxSqlStmt *S = luaL_checkudata(L, 1, UD_SQL_STMT);
	STMTCHECK(L,S)
	if (S->err == NULL) {
		lua_pushboolean(L,1);
		return 1;
	}
	lua_pushnil(L);
  lua_pushstring(L, S->err);
	return 2;
}


Lua
wax_sql_version(lua_State *L) {
	if (SQLITE_VERSION_NUMBER != sqlite3_libversion_number()) {
		luaL_error(L, "SQLite mismatched versions: header=%d lib=%d",
		           SQLITE_VERSION, sqlite3_libversion());
	}
	lua_pushstring(L,SQLITE_VERSION);
	lua_pushstring(L,SQLITE_SOURCE_ID);
	return 2;
}


/*//////// AUXILIAR FUNCTIONS ////////*/

/*
 * Sqlite has some strange behavior when last statement of a group
 * ends with semicolon (;). This function tries to circumvent this.
 *
 * Returns the original string and tbf == 0 or a
 * new allocated string and tbf == 1 (to be freed)
 * os tbf == -1 indicating allocation error
 */
char *sqltrim(const char *in, int *trimmed) {
	int len = strlen(in);
	int pos = len;
	char *out;
	while (--pos >= 0) switch(in[pos]) {
		case '\n' :
		case '\r' :
		case '\t' :
		case ' '  : continue;
		case '\0' : goto same;
		case ';'  : pos-=2;
		default   : goto trim;
	}
		
	trim:
		if (pos+1 >= len) goto same;
		len = pos+2;
		if ((out = malloc(sizeof(*out) * (len + 1))) == NULL) goto error;
		out[len] = '\0';
		out = memcpy(out, in, len);
		*trimmed = 1;
		return out;

	same:
		*trimmed = 0;
		return (char *)in;
		
	error:
		*trimmed = -1;
		return (char *)in;
}


/* return SQLITE_OK on success */
static int bindnames(waxSqlStmt *S, lua_State *L) {
	int rc = SQLITE_OK;
	int i;
	double number;
	lua_pushnil(L);

	if (lua_type(L,2) != LUA_TTABLE)
		luaL_error(L,"Named parameters require a record table with values");

	for (i = c8l_arrlen(S->bnames); i > 0; i--) {
		lua_getfield(L, 2, S->bnames[i-1]);
		switch(lua_type(L,-1)) {
			case LUA_TNUMBER:
				number = luaL_checknumber(L,-1);
				rc = is_int(number)
					? sqlite3_bind_int(S->S, i, (int) number)
					: sqlite3_bind_double(S->S, i, number);
				break;

			case LUA_TSTRING:
				rc = sqlite3_bind_text(S->S, i, luaL_checkstring(L,-1), -1, SQLITE_TRANSIENT);
				break;

			case LUA_TLIGHTUSERDATA:
				if (lua_touserdata(L,-1) == &wax_sql_null) rc = sqlite3_bind_null(S->S, i);
				break;

			default:
				return luaL_error(L, "Wrong value type for named parameter %q", S->bnames[i]);
		}
		lua_pop(L,1);
		if (rc != SQLITE_OK)
			return luaL_error(L, sqlite3_errstr(rc));
	}
	return rc;
}


/* return SQLITE_OK on success */
static int bindpos(waxSqlStmt *S, lua_State *L) {
	int lua_arg = lua_gettop(L);
	int sql_arg = lua_arg -1;
	int rc = SQLITE_OK;
	double number;
	
	l8n_assert(L,sql_arg >= S->bpos, /* -1 to not count the userdata first parameter */
	           "Insufficient values for statement");
	
	for( ; lua_arg > 1; lua_arg--, sql_arg-- ) {
		switch( lua_type(L, lua_arg) ) {
			case LUA_TNUMBER:
				number = luaL_checknumber(L, lua_arg);
				if ( is_int(number) )
					rc = sqlite3_bind_int(S->S, sql_arg, (int) number);
				else
					rc = sqlite3_bind_double(S->S, sql_arg, number);
				break;

			case LUA_TSTRING:
				rc = sqlite3_bind_text(S->S, sql_arg, luaL_checkstring(L,lua_arg), -1, SQLITE_TRANSIENT);
				break;

			case LUA_TLIGHTUSERDATA:
				if (lua_touserdata(L, lua_arg) != &wax_sql_null)
					return luaL_error(L, "Invalid type for field %d", sql_arg);
				rc = sqlite3_bind_null(S->S, sql_arg);
				break;
			
			default:
				return luaL_error(L, "Invalid type for field %d", sql_arg);
		}
		if (rc != SQLITE_OK) return luaL_error(L, sqlite3_errstr(rc));
	}
	return rc;
}
