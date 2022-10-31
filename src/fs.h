/*
 * Wax
 * A waxing Lua Standard Library
 *
 * Copyright (C) 2022 Thadeu A C de Paula
 * (https://github.com/waxlab/wax)
 */

#include "wax.h"
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
int luaopen_wax_fs(lua_State *L);
