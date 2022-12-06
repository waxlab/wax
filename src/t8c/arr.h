/* T8C Library - (c) 2022 Thadeu de Paula - Licensed under MIT Licence.

// Dynamic Heap Arrays
//
// This library provides functions and function like algoriths to
// create, manage and free dynamic arrays with C.
*/

#include <stdio.h>
#include <stdlib.h>
#ifndef T8C_ARR_INCLUDED
#define T8C_ARR_INCLUDED
typedef struct { size_t len, cap, tsz; } t8c_arr_t;

/*
/$ t8c_arrnew(ref_type, items) : int 1|0
// - ref_type : the variable or type used as size reference as in sizeof()
// - items    : initial number of items allocated in the array
// - returns 1 or 0 as success.
//
// If you can vaguely estimate the minimal of items, it is good
// to use this value as it can avoid excessive internal callings to
// realloc.
*/
#define t8c_arrnew(t,l) \
  M_t8c_arrnew(sizeof(t),(size_t)(l))

/*
/$ t8c_arr(array) : t8c_arr_t*
//
// Retrieves the array metadata struct. It can be modified but you should
// leave it to the library functions. The array should have been created using
// the `t8_arrnew()`.
//
// The structure values are:
// - `R->cap` : maximum capacity already allocated for the array
// - `R->len` : used capacity (length) of the array
// - `R->tsz` : number of bytes used per array item
*/
#define t8c_arr(a) (     \
  ((t8c_arr_t *)(a)) - 1 \
)

/*
/$ t8c_arrcapsz(array,items) : int 1|0
//
// Check if there is room for new `items` on `array` or try to allocate
// the needed space. Returns 1 in success (if there is space or it could be
// allocated) or 0 on error.
//
// On case of error, the error can be retrieved with errno/strerror
*/
#define t8c_arrcapsz(a,c) \
  M_t8c_arrcapsz((void *)&(a),(size_t)(c))

/*
/$ t8c_arrpush(array,value) : int 1|0
//
// Adds `value` at the end of `array` returning 1 on success or 0 on false.
// It internally does the array capacity management.
//
// On case of error, the error can be retrieved with errno/strerror
*/
#define t8c_arrpush(a,v) (              \
  (t8c_arr(a)->len+1 <= t8c_arr(a)->cap \
    || t8c_arrcapsz((a),1))             \
       ? ((a)[t8c_arr(a)->len++]=(v),1) \
       : 0 )

/*
/$ t8c_arrpop(array,default)
//
// Pops the last item of `array`, reducing its length. If the length of array
// is already 0 returns the specified `default` value.
*/
#define t8c_arrpop(a,default) ( \
  (t8c_arr(a)->len) > 0         \
    ? (a)[(--t8c_arr(a)->len)]  \
    : (default) )

#define t8c_arrfree(a) (         \
  (a) == NULL                    \
    ? NULL                       \
    : (                          \
      free((t8c_arr_t *)(a)-1),  \
      ((a)=NULL) ) )


/* GENERIC TYPE FUNCTIONS
 *
 * The functions and macros below are intended to:
 * - do the more complex part of the above macros
 * - make possible to deal with different types (polymorphism)
 */

void *M_t8c_arrnew(size_t sz, size_t l) {
  t8c_arr_t *a = realloc(NULL, (sz*l) + sizeof(t8c_arr_t));
  a[0].len=0;
  a[0].cap=l;
  a[0].tsz=sz;
  return (void *) (((t8c_arr_t *)a)+1);
}

#define t8c_shct_arrrsz \
  ((t8c_arr_t *)(*a)) - 1,sizeof(t8c_arr_t) + (nc * t8c_arr(*a)->tsz)

static int M_t8c_arrcapsz (void **a, size_t mincap) {
  t8c_arr_t *new;
  size_t nc = t8c_arr(*a)->cap;

  mincap += t8c_arr(*a)->len;
  while( (nc *= 2) < mincap );

  if (NULL == (new = realloc(t8c_shct_arrrsz))) return 0;

  *a = (void *) (new+1);
  t8c_arr(*a)->cap = nc;

  return 1;
}

#endif /* T8C_ARR_INCLUDED */
