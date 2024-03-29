/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/


/*
//## w/std.h - Basic tooling for C development
*/

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>


/*
//$ void wStd_error(char *msg, ...)
//| Prints an error message on stdout and for program exit with EXIT_STATUS=1.
//| The message can be formatted in the same way as `printf()`
*/
void wStd_error(char *msg, ...) {
  va_list va;
  va_start(va, msg);
  vfprintf(stderr, msg, va);
  exit(1);
  va_end(va);
}

/*
//$ void wStd_assert(int cond, char *msg, ...)
//| Evaluates `cond` and, if it is not true, send the message to the stderr and
//| exits with EXIT_STATUS=1.
//| The message can be formatted in the same way as `printf()`
*/
#define wStd_assert(cond, ...) \
  if (!(cond)) { wStd_error(__VA_ARGS__); }
