/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/
#define _POSIX_C_SOURCE 200112L

#include "../w/lua.h"
#include "../w/arr.h"
#include "../w/std.h"
#include "sys/socket.h"

#include "unistd.h"
#include "poll.h"

/****************\
** DECLARATIONS **
\****************/


typedef struct waxOsPipeline {
  int    fds[2];
} waxOsPipeline;

#define USERDATA "waxOsPipeline"
#define READ_SIZE 1024

Lua pipeline(lua_State *L);
Lua pipeline_write(lua_State *L);
Lua pipeline_read (lua_State *L);
Lua pipeline_close(lua_State *L);

static inline void mkpipe(lua_State *L, int *fds);
static inline int execsub(char *const *cmds, int fdin[2], int fdout[2]);


/***************\
** DEFINITIONS **
\***************/

LuaReg userdata_mt[] = {
  //{"write", pipeline_write},
  //{"read",  pipeline_read},
  //{"close", pipeline_close},
  {NULL,   NULL},
};


int luaopen_wax_os_pipeline(lua_State *L) {
  wLua_newuserdata_mt(L, USERDATA, userdata_mt);
  lua_pushcfunction(L, pipeline);
  return 1;
}


Lua pipeline(lua_State *L) {
  char **cmd;
  size_t counter;
  int pipe[2] = { -1, -1 };
  int pid;
  int icmd = 0;
  int arg;

  wLua_assert(L, lua_gettop(L), "Single argument expected");

  cmd = wArr_new(char *, 4);

 // int flags;
 // flags = fcntl(pipe.read, F_GETFL);
 // flags |= O_NONBLOCK;
 // fcntl(pipe.read, F_SETFL, flags);

  waxOsPipeline *ud = lua_newuserdata(L, sizeof(*ud));
  mkpipe(L, ud->fds);
  luaL_getmetatable(L, USERDATA);
  lua_setmetatable(L, -2);
  /* TODO */
  #if 0
  for (arg=1; arg <= top; arg++) {
    wArr_clear(cmd);

    /* Extract the argument as command */
    wLua_assert(L, lua_istable(L, arg), "Argument is not a table");
    lua_pushnil(L);
    while (lua_next(L, arg) != 0) {
      wArr_push(cmd, (char *)luaL_checkstring(L, -1));
      lua_pop(L, 1);
    }
    wArr_push(cmd, NULL);

    /* Fork and execute */
    execsub(L, cmd, pipe);

  }
  ud->pipe.read = pipe.read;
  #endif
  return 1;
}



/* -------------- Accessories ------------- */

static inline
void mkpipe(lua_State *L, int *fds) {
  wLua_assert(L,
              socketpair(AF_UNIX, SOCK_STREAM, 0, fds) != -1,
              strerror(errno));
}

static inline
int execsub(char *const *cmd, int *pin, int *pout) {
  int pid = fork();
  if (pid == 0) {
    wStd_assert(dup2(pin[0], STDIN_FILENO) == STDIN_FILENO,
                "dup pipein: %s", strerror(errno) );

    wStd_assert(dup2(pout[1], STDOUT_FILENO) == STDOUT_FILENO,
                "dup pipeout: %s", strerror(errno));

    close(pin[0]);  close(pin[1]);
    close(pout[0]); close(pout[1]);
    if( execvp(cmd[0], cmd) == -1 )
      die("Exec Error: %s", strerror(errno));
  }
  //return pid;
}
