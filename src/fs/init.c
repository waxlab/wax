/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/
#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 500

#include "../w/lua.h"
#include <stdlib.h>    /* realpath */
#include <sys/param.h> /* pmax Posix */
#include <sys/stat.h>  /* stat */
#include <limits.h>    /* pmax */
#include <libgen.h>    /* dirname, basename */
#include <math.h>      /* for floor() use */
#include <unistd.h>
#include <pwd.h>       /* for getpwnam */
#include <fcntl.h>     /* for AT_* constants on utime */
#include <dirent.h>
#include <glob.h>


#ifdef PLAT_WINDOWS
  static const char *DIRSEP="\\";
#else
  static const char *DIRSEP="/";
#endif

/* ///////// DECLARATION ///////// */

int luaopen_wax_fs_initc(lua_State *);

Lua
wax_fs_access     (lua_State *),
wax_fs_basename   (lua_State *),
wax_fs_buildpath  (lua_State *),
wax_fs_chdir      (lua_State *),
wax_fs_chmod      (lua_State *),
wax_fs_chown      (lua_State *),
wax_fs_exists     (lua_State *),
wax_fs_getcwd     (lua_State *),
wax_fs_getcwdname (lua_State *),
wax_fs_getmod     (lua_State *),
wax_fs_isblockdev (lua_State *),
wax_fs_ischardev  (lua_State *),
wax_fs_isdir      (lua_State *),
wax_fs_isfile     (lua_State *),
wax_fs_islink     (lua_State *),
wax_fs_ispipe     (lua_State *),
wax_fs_glob       (lua_State *),
wax_fs_list       (lua_State *),
wax_fs_mkdir      (lua_State *),
wax_fs_mkdirs     (lua_State *),
wax_fs_realpath   (lua_State *),
wax_fs_rmdir      (lua_State *),
wax_fs_stat       (lua_State *),
wax_fs_umask      (lua_State *),
wax_fs_unlink     (lua_State *),
wax_fs_utime      (lua_State *),
wax_fs_list_close (lua_State *),
wax_fs_glob_close (lua_State *),
iter_list         (lua_State *),
iter_glob         (lua_State *);

typedef struct timespec ts;
typedef struct { DIR *handler; int closed; } filels;
typedef struct { glob_t handler; size_t pos; } fileglob;

static int
aux_checkmode   (lua_State *L, int arg),
aux_checkpermstr(lua_State *L, int arg),
aux_mkdirp      (const char *inpath, int mode);

static ts
aux_checktstable(lua_State *L, int arg);

static char
*aux_filetype    (int st_mode),
*aux_fssanitize  (char *path, char *res);


LuaReg
wax_fs_list_mt[] = {
  #if LUA_VERSION_NUM >= 504
  {"__close", wax_fs_list_close },
  #endif
  {"__gc",    wax_fs_list_close },
  {"next",    iter_list         },
  {NULL,      NULL              }
};

LuaReg
wax_fs_glob_mt[] = {
  #if LUA_VERSION_NUM >= 504
  {"__close", wax_fs_glob_close },
  #endif
  {"__gc",    wax_fs_glob_close },
  {"next",    iter_glob         },
  {NULL,      NULL              }
};

LuaReg module[] = {
  {"access",     wax_fs_access     },
  {"basename",   wax_fs_basename   },
  {"buildpath",  wax_fs_buildpath  },
  {"chdir",      wax_fs_chdir      },
  {"chmod",      wax_fs_chmod      },
  {"chown",      wax_fs_chown      },
  {"dirname",    wax_fs_getcwdname },
  {"exists",     wax_fs_exists     },
  {"getcwd",     wax_fs_getcwd     },
  {"getmod",     wax_fs_getmod     },
  {"isblockdev", wax_fs_isblockdev },
  {"ischardev",  wax_fs_ischardev  },
  {"isdir",      wax_fs_isdir      },
  {"isfile",     wax_fs_isfile     },
  {"islink",     wax_fs_islink     },
  {"ispipe",     wax_fs_ispipe     },
  {"mkdirs",     wax_fs_mkdirs     },
  {"mkdir",      wax_fs_mkdir      },
  {"realpath",   wax_fs_realpath   },
  {"rmdir",      wax_fs_rmdir      },
  {"stat",       wax_fs_stat       },
  {"umask",      wax_fs_umask      },
  {"unlink",     wax_fs_unlink     },
  {"utime",      wax_fs_utime      },

  /* Generators/Iterators */
  {"list",       wax_fs_list       },
  {"glob",       wax_fs_glob       },

  /* Deprecated */
  {"listex",     wax_fs_glob       },

  { NULL,        NULL              }
};

#define glob_mt "wax_fs_glob_udata"
#define list_mt "wax_fs_list_udata"


/* ///////// IMPLEMENTATION ///////// */
int
luaopen_wax_fs_initc(lua_State *L) {

  wLua_newuserdata_mt(L, glob_mt, wax_fs_glob_mt);
  wLua_newuserdata_mt(L, list_mt, wax_fs_list_mt);

  wLua_export(L, module);
  lua_pushstring(L, DIRSEP);
  lua_setfield(L, -2, "dirsep");
  return 1;
}



/* * Path resolution * */

Lua
wax_fs_getcwdname(lua_State *L) {
  char path[PATH_MAX];
  const char *a1 = luaL_checkstring(L,1);
  size_t a1s = strlen(a1);
  if (a1s > PATH_MAX) {
    lua_pushnil(L);
    lua_pushstring(L, strerror(ENAMETOOLONG));
    return 2;
  }

  memcpy(path, a1, a1s+1);
  lua_pushstring(L, dirname(path));
  return 1;
}

Lua
wax_fs_basename(lua_State *L) {
  char path[PATH_MAX];
  const char *a1 = luaL_checkstring(L,1);
  size_t a1s = strlen(a1);
  if (a1s > PATH_MAX) {
    lua_pushnil(L);
    lua_pushstring(L, strerror(ENAMETOOLONG));
    return 2;
  }

  memcpy(path, a1, a1s+1);
  lua_pushstring(L, basename(path));
  return 1;
}

Lua
wax_fs_realpath(lua_State *L) {
  char out[PATH_MAX];
  wLua_failnil(L, realpath(luaL_checkstring(L, 1), out) == NULL);
  lua_pushstring(L,out);
  return 1;
}

Lua
wax_fs_buildpath(lua_State *L) {
  int plen   = 0,
      nlen   = 0,
      r      = 1,
      waxerr = 0,
      i;

  luaL_checkstring(L,1);


  const char *name;
  char path[PATH_MAX] = "\0";

  for (i = 1; i <= lua_gettop(L); i++) {
    name = luaL_checkstring(L,i);
    nlen = strlen(name);
    if ( (plen + 1 + nlen) >= PATH_MAX) {
      waxerr = ENAMETOOLONG;
      goto fail;
    }

    strcat(path, name);
    plen = plen + nlen;
    if (path[plen] != DIRSEP[0]) {
      strcat(path, DIRSEP);
      plen = plen + 1; /* +1 is for DIRSEP */
    }
  }

  char res[PATH_MAX];
  aux_fssanitize(path, res);
  lua_pushstring(L,res);
  r = 1;
  goto end;

  fail :
    lua_pushnil(L);
    lua_pushstring(L,strerror(waxerr));
    r = 2;
  end :
    return r;
}




/* * Stat related functions * */
static int
isStatMode(lua_State *L, unsigned int sm) {
  struct stat sb;
  const char *path = luaL_checkstring(L,1);
  wLua_failboolean(L, stat(path, &sb) == -1);
  lua_pushboolean(L, (sb.st_mode & S_IFMT) == sm);
  return 1;
}


Lua
wax_fs_stat(lua_State *L) {
  struct stat sb;
  const char *path = luaL_checkstring(L,1);
  wLua_failnil(L, stat(path, &sb) == -1);

  char tstr[30];

  lua_createtable(L,0,16);

  sprintf(tstr, "%lu", (unsigned long int) sb.st_dev);
  wLua_pair_ss(L, "dev",     tstr);

  sprintf(tstr, "%lu", (unsigned long int) sb.st_rdev);
  wLua_pair_ss(L, "rdev",    tstr);

  sprintf(tstr, "%03o", sb.st_mode & 0777);
  wLua_pair_ss(L, "mode",    tstr);

  wLua_pair_si(L, "ino",     sb.st_ino);

  wLua_pair_ss(L, "type",    aux_filetype(sb.st_mode));

  wLua_pair_si(L, "nlink",   sb.st_nlink);
  wLua_pair_si(L, "uid",     sb.st_uid);
  wLua_pair_si(L, "gid",     sb.st_gid);
  wLua_pair_si(L, "size",    sb.st_size);
  wLua_pair_si(L, "blksize", sb.st_blksize);
  wLua_pair_si(L, "blocks",  sb.st_blocks);
  wLua_pair_si(L, "atime",   sb.st_atim.tv_sec);
  wLua_pair_si(L, "ctime",   sb.st_ctim.tv_sec);
  wLua_pair_si(L, "mtime",   sb.st_mtim.tv_sec);

  /* Some systems doesn't support these below. In that case, they are 0 */
  wLua_pair_si(L, "atimens", sb.st_atim.tv_nsec);
  wLua_pair_si(L, "ctimens", sb.st_ctim.tv_nsec);
  wLua_pair_si(L, "mtimens", sb.st_mtim.tv_nsec);

  return 1;
}


static ts
aux_checktstable(lua_State *L, int arg){
  ts ts;

  lua_pushnumber(L, 1);
  lua_gettable(L, arg);
  ts.tv_sec = luaL_checknumber(L, -1);
  lua_pop(L, 1);

  lua_pushnumber(L, 2);
  lua_gettable(L, arg);
  ts.tv_nsec = luaL_checknumber(L, -1);
  lua_pop(L, 1);
  return ts;
}


Lua
wax_fs_utime(lua_State *L) {
  const char *path = luaL_checkstring(L,1);
  ts update[2];
  double sec;
  double nsec;
  int argc = lua_gettop(L);

  /* for modification time */
  if (argc < 2 || lua_isnil(L,2)) {
    update[1].tv_nsec = UTIME_OMIT;
    /* If not should update returns false to Lua */
    if (update[0].tv_nsec == UTIME_OMIT) {
      lua_pushboolean(L, 0);
      return 1;
    }
  } else if (lua_istable(L, 2)) {
    update[1] = aux_checktstable(L, 2);
  } else {
    nsec = modf(luaL_checknumber(L, 2), &sec);
    if (sec < 0) {
      update[1].tv_nsec = UTIME_NOW;
    } else {
      update[1].tv_sec = sec;
      update[1].tv_nsec = (int) (nsec * 1000000000);
    }
  }

  /* for access time */
  if (argc < 3 || lua_isnil(L,3)) {
      update[0].tv_nsec = UTIME_NOW;
  } else if (lua_istable(L, 3)) {
    update[0] = aux_checktstable(L, 3);
  } else {
    nsec = modf(luaL_checknumber(L, 3), &sec);
    if (sec < 0) {
      update[0].tv_nsec = UTIME_NOW;
    } else {
      update[0].tv_sec = sec;
      update[0].tv_nsec = (int) (nsec * 1000000000);
    }
  }

  wLua_failboolean(L, utimensat(AT_FDCWD, path, update, 0) < 0);
  lua_pushboolean(L, 1);
  return 1;
}


Lua
wax_fs_access(lua_State *L) {
  const char *path = luaL_checkstring(L,1);
  int mode = F_OK;

  switch (lua_type(L,2)) {
    case LUA_TNUMBER:
      mode = lua_tointeger(L,2);
      break;
    case LUA_TSTRING:
      mode = aux_checkpermstr(L,2);
      break;
    default:
      lua_pushstring(L,"mode should be a string or an integer");
      lua_error(L);
      return 0;
  }

  if (1 > mode || mode > 7) {
    lua_pushstring(L,"Numeric mode must be one from 1 to 7");
    lua_error(L);
    return 0;
  }

  wLua_failboolean(L, access(path,mode) < 0);
  lua_pushboolean(L,1);
  return 1;
}


Lua
wax_fs_getmod(lua_State *L) {
  struct stat sb;
  wLua_failnil(L, stat(luaL_checkstring(L,1), &sb) < 0);

  char mode[4];
  sprintf(mode, "%03o", sb.st_mode & 0777);
  lua_pushstring(L, mode);

  return 1;
}


Lua
wax_fs_chmod(lua_State *L) {
  wLua_failboolean(L, chmod(luaL_checkstring(L,1), aux_checkmode(L,2)) < 0);
  lua_pushboolean(L,1);
  return 1;
}


Lua
wax_fs_chown(lua_State *L) {
  int uid = -1;
  const char *path = luaL_checkstring(L, 1);
  int uargtype = lua_type(L,2);
  if (uargtype == LUA_TSTRING) {
    struct passwd *p = getpwnam(luaL_checkstring(L,2));
    wLua_failboolean(L, p == NULL);
    uid = p->pw_uid;
  } else if (uargtype == LUA_TNUMBER) {
    uid = luaL_checkinteger(L,2);
  } else {
    luaL_error(L,"expected string or number as 2ng arg");
  }

  wLua_failboolean(L, chown(path, uid, -1) < 0);
  lua_pushboolean(L,1);
  return 1;
}


Lua
wax_fs_isdir(lua_State *L)      { return isStatMode(L, S_IFDIR); }

Lua
wax_fs_isfile(lua_State *L)     { return isStatMode(L, S_IFREG); }

Lua
wax_fs_islink(lua_State *L)     { return isStatMode(L, S_IFLNK); }

Lua
wax_fs_isblockdev(lua_State *L) { return isStatMode(L, S_IFBLK); }

Lua
wax_fs_ischardev(lua_State *L)  { return isStatMode(L, S_IFCHR); }

Lua
wax_fs_ispipe(lua_State *L)     { return isStatMode(L, S_IFIFO); }


Lua
wax_fs_exists(lua_State *L) {
  wLua_failboolean(L, access(luaL_checkstring(L,1), F_OK) < 0);
  lua_pushboolean(L,1);
  return 1;
}


Lua
wax_fs_umask(lua_State *L) {
  int omask;
  if ( lua_gettop(L) == 0 ) {
    omask = umask(0022);
    if (omask != 0022) umask(omask);
  } else {
    omask = umask(aux_checkmode(L,1));
  }

  char mask[4];
  sprintf(mask, "%03o", omask & 0777);
  lua_pushstring(L,mask);
  return 1;
}

Lua
wax_fs_getcwd(lua_State *L) {
  char cwd[PATH_MAX + 1];
  wLua_failnil(L, getcwd(cwd,PATH_MAX) == NULL);
  lua_pushstring(L,cwd);
  return 1;
}

Lua
wax_fs_chdir(lua_State *L) {
  wLua_failboolean(L, chdir(luaL_checkstring(L,1)) < 0);
  lua_pushboolean(L,1);
  return 1;
}

Lua
wax_fs_mkdir(lua_State *L) {
  wLua_failboolean(L, mkdir(luaL_checkstring(L,1), aux_checkmode(L,2)) < 0);
  lua_pushboolean(L,1);
  return 1;
}

static int
aux_mkdirp(const char *inpath, int mode) {
  struct stat sb;
  int  test = 1,
       i, plen;
  char sep = DIRSEP[0],
       path[PATH_MAX];

  aux_fssanitize((char *)inpath, path);
  plen = strlen(path);

  /* map the position of separators, rtl */
  for (i = 1; i<=plen; i++) {
    if (i< plen) {
      if (path[i] != sep) continue;
      path[i] = '\0';
    }
    if (test) {
      if (stat(path, &sb) == 0) { /* if exists */
        if (S_ISDIR(sb.st_mode)) goto cont;
        errno=ENOTDIR;
        return 0;
      }
      test = 0; /* from here will start create */
    }
    if (mkdir(path, mode) == -1) return -1;
    cont : path[i] = sep;
  }
  return 0; /* 0 is success like in mkdir */
}

Lua
wax_fs_mkdirs(lua_State *L) {
  wLua_failboolean(L, aux_mkdirp(luaL_checkstring(L,1), aux_checkmode(L,2)) < 0);
  lua_pushboolean(L,1);
  return 1;
}

Lua
wax_fs_rmdir(lua_State *L) {
  wLua_failboolean(L, rmdir(luaL_checkstring(L,1)) < 0);
  lua_pushboolean(L,1);
  return 1;
}

Lua
wax_fs_unlink(lua_State *L) {
  wLua_failboolean(L, unlink(luaL_checkstring(L,1)) < 0);
  lua_pushboolean(L,1);
  return 1;
}


/* * Directory entry listing * */

Lua
iter_list(lua_State *L) {
  filels *data = lua_touserdata(L, lua_upvalueindex(1));
  errno = 0;
  struct dirent *entry;

  entry = readdir(data->handler);

  if (entry == NULL) {
    if (errno) {
      lua_pushstring(L,strerror(errno));
      return lua_error(L);
    }
    return 0;
  }

  lua_pushstring(L,entry->d_name);
  return 1; 
}

Lua
wax_fs_list(lua_State *L) {
  const char *path = luaL_checkstring(L,1);
  filels *data = lua_newuserdata(L, sizeof(filels));
  data->handler = opendir(path);
  data->closed = 0;

  if (data->handler == NULL) {
    lua_pushstring(L, strerror(errno));
    return lua_error(L);
  }

  luaL_getmetatable(L,list_mt);
  lua_setmetatable(L,-2);
  lua_pushvalue(L,-1);
  lua_pushcclosure(L, iter_list, 1);
  return 1;
}

Lua
wax_fs_list_close(lua_State *L) {
  filels *data = luaL_checkudata(L,1,list_mt);
  int res = 0;

  if (! data->closed ) {
    res = closedir(data->handler);
    data->closed = 1;
  }

  lua_pushboolean(L, res);
  return 0;
}


/* * Directory entry listing with word expansions * */


Lua
wax_fs_glob(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  fileglob *data = lua_newuserdata(L, sizeof(fileglob));

  /* We ignore errors just in glob */
  glob(path, 0, NULL, &(data->handler));

  data->pos = 0;
  luaL_getmetatable(L, glob_mt);
  lua_setmetatable(L,-2);
  lua_pushvalue(L,-1);
  lua_pushcclosure(L, iter_glob,1);
  return 1;
}

Lua
wax_fs_glob_close(lua_State *L) {
  fileglob *data = luaL_checkudata(L,1,glob_mt);
  globfree( &(data->handler) );
  return 0;
}

Lua
iter_glob(lua_State *L) {
  fileglob *data =  lua_touserdata(L, lua_upvalueindex(1));

  if (data->pos >= data->handler.gl_pathc) return 0;

  lua_pushstring(L, data->handler.gl_pathv[data->pos ++]);
  return 1;
}


/* get a string containing octal repr. of mode from an argument */
static int
aux_checkmode(lua_State *L, int arg) {
  char *e;
  int mode = strtol(luaL_checkstring(L,arg), &e, 8);
  wLua_assert(L, e[0] == '\0', "invalid octal");
  return mode;
}

/* string "r", "w" or "x" to integer permission */
static int
aux_checkpermstr(lua_State *L, int arg) {
  int mode = F_OK,
      i;
  const char *strmode = luaL_checkstring(L, arg);
  for (i = 0; strmode[i] != 0; i++) {
    switch (strmode[i]) {
      case 'r' : mode |= R_OK; break;
      case 'w' : mode |= W_OK; break;
      case 'x' : mode |= X_OK; break;
      default:
        wLua_error(L,"Mode character different of 'r','w' or 'x'");
    }
  }
  return mode;
}

static char
*aux_filetype(int st_mode) {
  if((st_mode & S_IFMT) == S_IFREG) return "file";
  if((st_mode & S_IFMT) == S_IFDIR) return "dir";
  if((st_mode & S_IFMT) == S_IFIFO) return "fifo";
  if((st_mode & S_IFMT) == S_IFBLK) return "block";
  if((st_mode & S_IFMT) == S_IFCHR) return "char";
  return "other";
}

static char
*aux_fssanitize(char *path, char *res) {
  int p=0;  /* index counter for path chars */
  int r=-1; /* index counter for result chars */
  int pl = strlen(path);
  char sep = DIRSEP[0];

  while (p <= pl) {
    /* remove './' from the middle of path */
    if( p > 0 && path[p] == '.'
              && p+2 <= pl
              && path[p+1] == sep
              && path[p-1] == sep
    ) p=p+2;

    /* remove repeated consecutive '/' from path */
    if (r >= 0 && res[r] == sep && path[p] == sep)
      p++;
    else
      res[++r] = path[p++];
  }

  if (r >= 0) {
    /* avoid separator as last char */
    if (r > 0 && res[r-1] == sep) res[r-1] = '\0';
    else res[r] = '\0';
  }

  return res;
}


/* vim: set fdn=1 fdm=indent fdn=1 ts=2 sts=2 sw=2: */
