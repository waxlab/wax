/*
** Wax
** A waxing Lua Standard Library
**
** Copyright (C) 2022 Thadeu A C de Paula
** (https://github.com/luawax/wax)
*/

/*
** This header stores macros that simplifies Lua data handling.
** Using these macros you will write less code, avoid common mistakes
** and, even you have a specialized code, you can use these as
** reference of how to deeper stuffs are done
*/

#include "lume.h"


/*
** DEFINITIONS
*/

#if defined(_WIN32) || defined(WIN64)
  #define PLAT_WINDOWS
#elif __unix__
  #define PLAT_POSIX
#endif


#ifndef PATH_MAX
  #ifdef NAME_MAX
    const int PATH_MAX = NAME_MAX;
  #elif MAXPATHLEN
    const int PATH_MAX = MAXPATHLEN;
  #endif
#endif



/*
** FUNCTIONS
*/

/* Use it when filling compatibility gaps on modules. */
int unimplemented(lua_State *L, ...);



