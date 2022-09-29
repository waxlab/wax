/*
** Wax
** A waxing Lua Standard Library
**
** Copyright (C) 2022 Thadeu A C de Paula
** (https://github.com/waxlab/wax)
*/

#include <stdlib.h>    /* realpath */
#include <sys/param.h> /* pmax Posix */
#include <sys/stat.h>  /* stat */
#include <limits.h>    /* pmax */
#include <libgen.h>    /* dirname, basename */
#include <string.h>
#include <errno.h>
#include <math.h>      /* for floor() use */
#include <unistd.h>
#include <pwd.h>       /* for getpwnam */
#include <fcntl.h>     /* for AT_* constants on utime */
#include <dirent.h>
#include <glob.h>
#include "path.h"


#ifdef PLAT_WINDOWS
  static const char *DIRSEP="\\";
#else
  static const char *DIRSEP="/";
#endif


/* get a string containing octal repr. of mode from an argument */
static int _wax_checkmode(lua_State *L, int arg) {
  char *e;
  int mode = strtol(luaL_checkstring(L,arg), &e, 8);
  waxM_error(L, e[0] != '\0', "invalid octal");
  return mode;
}


/* string "r", "w" or "x" to integer permission */
static int _wax_checkpermstring(lua_State *L, int arg) {
  int mode = F_OK;
  const char *strmode = luaL_checkstring(L, arg);
  for (int i=0; strmode[i] != 0; i++) {
    switch (strmode[i]) {
      case 'r' : mode |= R_OK; break;
      case 'w' : mode |= W_OK; break;
      case 'x' : mode |= X_OK; break;
      default:
        waxM_error(L,1,"Mode character different of 'r','w' or 'x'");
    }
  }
  return mode;
}


static char *_wax_filetype(int st_mode) {
  if((st_mode & S_IFMT) == S_IFREG) return "file";
  if((st_mode & S_IFMT) == S_IFDIR) return "dir";
  if((st_mode & S_IFMT) == S_IFIFO) return "fifo";
  if((st_mode & S_IFMT) == S_IFBLK) return "block";
  if((st_mode & S_IFMT) == S_IFCHR) return "char";
  return "other";
}


static char *_wax_pathsanitize(char *path, char *res) {
  int p=0;  /* index counter for path chars */
  int r=-1; /* index counter for result chars */
  int pl = strlen(path);
  char sep = DIRSEP[0];

  while (p <= pl) {
    /* remove './' from the middle of path */
    if( p > 0
      && path[p] == '.'
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



/*
** Path resolution
*/

static int wax_path_getcwdname(lua_State *L) {
  char path[PATH_MAX];
  const char *arg1 = luaL_checkstring(L,1);
  memcpy(path, arg1, strlen(arg1)+1);

  lua_pushstring(L, dirname(path));
  return 1;
}


static int wax_path_basename(lua_State *L) {
  char path[PATH_MAX];
  const char *arg1 = luaL_checkstring(L,1);
  memcpy(path, arg1, strlen(arg1)+1);

  lua_pushstring(L, basename(path));
  return 1;
}


static int wax_path_real(lua_State *L) {
  char out[PATH_MAX];
  waxM_failnil(L, realpath(luaL_checkstring(L, 1), out) == NULL);
  lua_pushstring(L,out);
  return 1;
}


static int wax_path_build(lua_State *L) {
  luaL_checkstring(L,1);

  int plen=0, nlen=0, r=1, waxerr=0;

  const char *name;
  char path[PATH_MAX] = "\0";

  for (int i = 1 ; i <= lua_gettop(L); i++) {
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
  _wax_pathsanitize(path, res);
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




/*
** Stat related functions
*/
static int isStatMode(lua_State *L, unsigned int sm) {
  struct stat sb;
  const char *path = luaL_checkstring(L,1);
  waxM_failboolean(L, stat(path, &sb) == -1);
  lua_pushboolean(L, (sb.st_mode & S_IFMT) == sm);
  return 1;
}


static int wax_path_stat(lua_State *L) {
  struct stat sb;
  const char *path = luaL_checkstring(L,1);
  waxM_failnil(L, stat(path, &sb) == -1);

  char tstr[30];

  lua_createtable(L,0,16);

  sprintf(tstr, "%lu", (unsigned long int) sb.st_dev);
  waxM_setfield_ss(L, "dev",     tstr);

  sprintf(tstr, "%lu", (unsigned long int) sb.st_rdev);
  waxM_setfield_ss(L, "rdev",    tstr);

  sprintf(tstr, "%03o", sb.st_mode & 0777);
  waxM_setfield_ss(L, "mode",    tstr);

  waxM_setfield_si(L, "ino",     sb.st_ino);

  waxM_setfield_ss(L, "type",    _wax_filetype(sb.st_mode));

  waxM_setfield_si(L, "nlink",   sb.st_nlink);
  waxM_setfield_si(L, "uid",     sb.st_uid);
  waxM_setfield_si(L, "gid",     sb.st_gid);
  waxM_setfield_si(L, "size",    sb.st_size);
  waxM_setfield_si(L, "blksize", sb.st_blksize);
  waxM_setfield_si(L, "blocks",  sb.st_blocks);
  waxM_setfield_si(L, "atime",   sb.st_atim.tv_sec);
  waxM_setfield_si(L, "ctime",   sb.st_ctim.tv_sec);
  waxM_setfield_si(L, "mtime",   sb.st_mtim.tv_sec);

  /* Some systems doesn't support these below. In that case, they are 0 */
  waxM_setfield_si(L, "atimens", sb.st_atim.tv_nsec);
  waxM_setfield_si(L, "ctimens", sb.st_ctim.tv_nsec);
  waxM_setfield_si(L, "mtimens", sb.st_mtim.tv_nsec);

  return 1;
}


static struct timespec _wax_checktstable(lua_State *L, int arg){
  struct timespec ts;

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


static int wax_path_utime(lua_State *L) {
  const char *path = luaL_checkstring(L,1);
  struct timespec update[2];
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
    update[1] = _wax_checktstable(L, 2);
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
    update[0] = _wax_checktstable(L, 3);
  } else {
    nsec = modf(luaL_checknumber(L, 3), &sec);
    if (sec < 0) {
      update[0].tv_nsec = UTIME_NOW;
    } else {
      update[0].tv_sec = sec;
      update[0].tv_nsec = (int) (nsec * 1000000000);
    }
  }

  waxM_failboolean(L, utimensat(AT_FDCWD, path, update, 0) < 0);
  lua_pushboolean(L, 1);
  return 1;
}


static int wax_path_access(lua_State *L) {
  const char *path = luaL_checkstring(L,1);
  int mode = F_OK;

  switch (lua_type(L,2)) {
    case LUA_TNUMBER:
      mode = lua_tointeger(L,2);
      break;
    case LUA_TSTRING:
      mode = _wax_checkpermstring(L,2);
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

  waxM_failboolean(L, access(path,mode) < 0);
  lua_pushboolean(L,1);
  return 1;
}


static int wax_path_getmod(lua_State *L) {
  struct stat sb;
  waxM_failnil(L, stat(luaL_checkstring(L,1), &sb) < 0);

  char mode[4];
  sprintf(mode, "%03o", sb.st_mode & 0777);
  lua_pushstring(L, mode);

  return 1;
}


static int wax_path_chmod(lua_State *L) {
  waxM_failboolean(L, chmod(luaL_checkstring(L,1), _wax_checkmode(L,2)) < 0);
  lua_pushboolean(L,1);
  return 1;
}


static int wax_path_chown(lua_State *L) {
  int uid = -1;
  const char *path = luaL_checkstring(L, 1);
  int uargtype = lua_type(L,2);
  if (uargtype == LUA_TSTRING) {
    struct passwd *p = getpwnam(luaL_checkstring(L,2));
    waxM_failboolean(L, p == NULL);
    uid = p->pw_uid;
  } else if (uargtype == LUA_TNUMBER) {
    uid = luaL_checkinteger(L,2);
  } else {
    luaL_error(L,"expected string or number as 2ng arg");
  }

  waxM_failboolean(L, chown(path, uid, -1) < 0);
  lua_pushboolean(L,1);
  return 1;
}


static int wax_path_isdir(lua_State *L)      { return isStatMode(L, S_IFDIR); }
static int wax_path_isfile(lua_State *L)     { return isStatMode(L, S_IFREG); }
static int wax_path_islink(lua_State *L)     { return isStatMode(L, S_IFLNK); }
static int wax_path_isblockdev(lua_State *L) { return isStatMode(L, S_IFBLK); }
static int wax_path_ischardev(lua_State *L)  { return isStatMode(L, S_IFCHR); }
static int wax_path_ispipe(lua_State *L)     { return isStatMode(L, S_IFIFO); }


static int wax_path_exists(lua_State *L) {
  waxM_failboolean(L, access(luaL_checkstring(L,1), F_OK) < 0);
  lua_pushboolean(L,1);
  return 1;
}


static int wax_path_umask(lua_State *L) {
  int omask;
  if ( lua_gettop(L) == 0 ) {
    omask = umask(0022);
    if (omask != 0022) umask(omask);
  } else {
    omask = umask(_wax_checkmode(L,1));
  }

  char mask[4];
  sprintf(mask, "%03o", omask & 0777);
  lua_pushstring(L,mask);
  return 1;
}


static int wax_path_getcwd(lua_State *L) {
  char cwd[PATH_MAX + 1];
  waxM_failnil(L, getcwd(cwd,PATH_MAX) == NULL);
  lua_pushstring(L,cwd);
  return 1;
}


static int wax_path_chdir(lua_State *L) {
  waxM_failboolean(L, chdir(luaL_checkstring(L,1)) < 0);
  lua_pushboolean(L,1);
  return 1;
}


static int wax_path_mkdir(lua_State *L) {
  waxM_failboolean(L, mkdir(luaL_checkstring(L,1), _wax_checkmode(L,2)) < 0);
  lua_pushboolean(L,1);
  return 1;
}


static int _wax_mkdirp(const char *inpath, int mode) {
  struct stat sb;
  int test = 1;
  char path[PATH_MAX];
  int  plen;
  char sep     = DIRSEP[0];      /* is "/" or "\" ? */

  _wax_pathsanitize((char *)inpath, path);
  plen = strlen(path);

  /* map the position of separators, rtl */
  for (int i=1; i<=plen; i++) {
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


static int wax_path_mkdirs(lua_State *L) {
  waxM_failboolean(L, _wax_mkdirp(luaL_checkstring(L,1), _wax_checkmode(L,2)) < 0);
  lua_pushboolean(L,1);
  return 1;
}


static int wax_path_rmdir(lua_State *L) {
  waxM_failboolean(L, rmdir(luaL_checkstring(L,1)) < 0);
  lua_pushboolean(L,1);
  return 1;
}


static int wax_path_unlink(lua_State *L) {
  waxM_failboolean(L, unlink(luaL_checkstring(L,1)) < 0);
  lua_pushboolean(L,1);
  return 1;
}


/*
** Directory entry listing
*/

#define list_mt "wax_path_list_udata"

typedef struct {
  DIR *handler;
  int closed;
} list_t;


static int wax_path_list_iter(lua_State *L) {
  list_t *data = luaL_checkudata(L, 1, list_mt);
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


static int wax_path_list_open(lua_State *L) {
  const char *path = luaL_checkstring(L,1);
  lua_pushcfunction(L, wax_path_list_iter);
  list_t *data = lua_newuserdata(L, sizeof(list_t));
  data->handler = opendir(path);
  data->closed = 0;

  if (data->handler == NULL) {
    lua_pushstring(L, strerror(errno));
    return lua_error(L);
  }

  luaL_getmetatable(L,list_mt);
  lua_setmetatable(L,-2);
  return 2;
}


static int wax_path_list_close(lua_State *L) {
  list_t *data = luaL_checkudata(L,1,list_mt);
  int res = 0;

  if (! data->closed ) {
    res = closedir(data->handler);
    data->closed = 1;
  }

  lua_pushboolean(L, res);
  return 0;
}


static const luaL_Reg wax_path_list_mt[] = {
  #if LUA_VERSION_NUM >= 504
  {"__close", wax_path_list_close },
  #endif
  {"__gc",  wax_path_list_close },
  {"next",  wax_path_list_iter },
  {NULL,    NULL             }
};


/*
** Directory entry listing with word expansions
*/

#define listex_mt "wax_path_listex_udata"

typedef struct {
  glob_t handler;
  size_t pos;
} listex_t;


static int wax_path_listex_iter(lua_State *L) {
  listex_t *data = luaL_checkudata(L, 1, listex_mt);

  if (data->pos >= data->handler.gl_pathc) return 0;

  lua_pushstring(L, data->handler.gl_pathv[data->pos ++]);
  return 1;
}


static int wax_path_listex_open(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  lua_pushcfunction(L, wax_path_listex_iter);
  listex_t *data = lua_newuserdata(L, sizeof(listex_t));

  /* We ignore errors just in listex */
  glob(path, 0, NULL, &(data->handler));

  data->pos = 0;
  luaL_getmetatable(L, listex_mt);
  lua_setmetatable(L,-2);
  return 2;
}


static int wax_path_listex_close(lua_State *L) {
  listex_t *data = luaL_checkudata(L,1,listex_mt);
  globfree( &(data->handler) );
  return 0;
}


static const luaL_Reg wax_path_listex_mt[] = {
  #if LUA_VERSION_NUM >= 504
  {"__close", wax_path_listex_close },
  #endif
  {"__gc",  wax_path_listex_close },
  {"next",  wax_path_listex_iter },
  {NULL,    NULL             }
};



/*
** Module exported functions
*/

static const luaL_Reg wax_path[] = {
  {"real",       wax_path_real             },
  {"build",      wax_path_build            },
  {"dirname",    wax_path_getcwdname       },
  {"basename",   wax_path_basename         },

  {"stat",       wax_path_stat             },
  {"utime",      wax_path_utime            },
  {"access",     wax_path_access           },
  {"getmod",     wax_path_getmod           },
  {"chmod",      wax_path_chmod            },
  {"chown",      wax_path_chown            },

  {"exists",     wax_path_exists           },
  {"umask",      wax_path_umask            },
  {"isblockdev", wax_path_isblockdev       },
  {"ischardev",  wax_path_ischardev        },
  {"isdir",      wax_path_isdir            },
  {"isfile",     wax_path_isfile           },
  {"ispipe",     wax_path_ispipe           },
  {"islink",     wax_path_islink           },

  {"getcwd",     wax_path_getcwd           },
  {"chdir",      wax_path_chdir            },
  {"mkdir",      wax_path_mkdir            },
  {"mkdirs",     wax_path_mkdirs           },
  {"rmdir",      wax_path_rmdir            },
  {"unlink",     wax_path_unlink           },

  /* Generators/Iterators */
  {"list",       wax_path_list_open        },
  {"listex",     wax_path_listex_open      },

  { NULL,        NULL                      }
};


int luaopen_wax_path(lua_State *L) {

  waxM_newuserdata_mt(L, listex_mt, wax_path_listex_mt);
  waxM_newuserdata_mt(L, list_mt,   wax_path_list_mt);

  waxM_export(L, "wax.path", wax_path);
  lua_pushstring(L, DIRSEP);
  lua_setfield(L, -2, "dirsep");
  return 1;
}
