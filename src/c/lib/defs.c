/*************************************************\
||                                               ||
||        EOS - Extension Library for Lua        ||
||                                               ||
||    Copyright (C)  2022 Thadeu A C de Paula    ||
||                                               ||
|| This program is free software under the terms ||
|| of the GNU General Public License - version 3 ||
|| as published in  https://www.gnu.org/licenses ||
||                                               ||
\*************************************************/

#include "defs.h"

int unimplemented(lua_State *L, ...) {
  lua_pushnil(L);
  return 1;
}
