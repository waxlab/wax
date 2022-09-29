#include <stdlib.h>    /* realpath */
#include <stdio.h>
#include "waxm.h"
#include "json.h"
#include <string.h>

/*
** MACROS
*/

#define jStr cJSON_IsString
#define jNum cJSON_IsNumber
#define jBoo cJSON_IsBool
#define jObj cJSON_IsObject
#define jArr cJSON_IsArray
#define jNul cJSON_IsNull

#define mlua_pushnumber(L,j) \
  if ((j)->valuedouble>(j->valueint)) \
    lua_pushnumber((L),(j->valuedouble)); \
  else \
    lua_pushinteger((L),(j->valueint));

#define mlua_pushludata(L,d) lua_pushlightuserdata((L),(void *)&(d));


/*
** DECLARATIONS
*/

struct json_cfg {
  int level;
  int stack_size;
};

static int json_null = 0;

static void jObj_to_lua(lua_State *L, struct cJSON *node, int len, struct json_cfg *cfg);
static void jArr_to_lua(lua_State *L, struct cJSON *node, int len, struct json_cfg *cfg);
static void cjson_to_lua(lua_State *L, struct cJSON *root, struct json_cfg *cfg);


/*
** FUNCTIONS
*/
static void jObj_to_lua(lua_State *L, struct cJSON *node, int len, struct json_cfg *cfg) {
  cfg->level+=3;
  if ( cfg->level > cfg->stack_size && lua_checkstack(L, 3) ) {
    lua_createtable(L,0,len);
    for (int i=0; i < len; i++) {
      lua_pushstring(L, node->string); /* The object key */
      cjson_to_lua(L, node, cfg);
      lua_settable(L,-3);
      node = node->next;
    }
  } else {
    char msg[100]="\0";
    sprintf(msg, "too much nesting on json. Stopping at level %d with Stack size %d\n",
           (((cfg->level) - LUA_MINSTACK)/3), cfg->stack_size);
    lua_pushstring(L,msg);
    lua_error(L);
  }
}

static void jArr_to_lua(lua_State *L, struct cJSON *node, int len, struct json_cfg *cfg) {
  cfg->level+=3;
  if ( cfg->level > cfg->stack_size && lua_checkstack(L, 3) ) {
    lua_createtable(L,len,0);
    for (int i=1; i <= len; i++) {
      lua_pushinteger(L, i); /* The object key */
      cjson_to_lua(L, node, cfg);
      lua_settable(L,-3);
      node = node->next;
    }
  } else {
    char msg[100]="\0";
    sprintf(
      msg,
      "Too much JSON levels. Level: %d; Lua stack: %d\n",
      ( ( (cfg->level) - LUA_MINSTACK) / 3),
      cfg->stack_size
    );
    lua_pushstring(L,msg);
    lua_error(L);
  }
}


static void cjson_to_lua(lua_State *L, struct cJSON *n, struct json_cfg *c) {
  if (jObj(n)) { jObj_to_lua(L, n->child, cJSON_GetArraySize(n), c); return;}
  if (jArr(n)) { jArr_to_lua(L, n->child, cJSON_GetArraySize(n), c); return;}
  if (jStr(n)) { lua_pushstring (L, n->valuestring); return;}
  if (jNum(n)) { mlua_pushnumber(L, n             ); return;}
  if (jBoo(n)) { lua_pushboolean(L, n->valueint   ); return;}
  if (jNul(n)) { mlua_pushludata(L, json_null     ); return;}
}


/*
** MODULE PUBLISHED FUNCTIONS
*/

static int wax_json_decode(lua_State *L) {
  struct cJSON *json = cJSON_Parse(luaL_checkstring(L, 1));
  struct json_cfg cfg = {LUA_MINSTACK, LUA_MINSTACK};
  cjson_to_lua(L, json, &cfg);
  cJSON_Delete(json);
  return 1;
}

static int wax_json_encode(lua_State *L) {
  lua_pushnil(L);
  cJSON *res= cJSON_CreateObject();
  cJSON *node;
  while (lua_next(L,-2) != 0) {
    node = cJSON_CreateString(lua_tostring(L, -1));
    if (node != NULL) {
      cJSON_AddItemToObject(res, lua_tostring(L, -2), node);
    }
    lua_pop(L,1);
  }
  lua_pushstring(L,cJSON_Print(res));
  return 1;
}


/*
** Module exported functions
*/

static const luaL_Reg wax_json[] = {
  {"decode",     wax_json_decode           },
  {"encode",     wax_json_encode           },
  { NULL,        NULL                      }
};


int luaopen_wax_json(lua_State *L) {
  waxM_export(L, "wax.json", wax_json);
  lua_pushlightuserdata(L, (void *) &json_null);
  lua_setfield(L,-2, "null");
  return 1;
}
