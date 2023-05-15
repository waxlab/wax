/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/

/*
//## w/arr.h - Dynamic Heap Arrays
//|
//| This library provides functions and function like algoriths to
//| create, manage and free dynamic arrays with C.
//|
//| It basically allocates memory for a 3 size_t array plus the amount
//| requested in operations for any specified type.
//|
//| So if you want an array of 5 chars (a string!):
//|
//| ```
//|             |
//| | 0 | 1 | 2 | 0 | 1 | 2 | 3 | 4 |
//| < meta data | space to store your
//|   in size_t |    data (char *)
//|             |
//|  Hidden     | Exposed to your app
//| ```
*/

#include <stdio.h>
#include <stdlib.h>
#ifndef WAX_ARR_INCLUDED
#define WAX_ARR_INCLUDED

/*
//$ void *wArr_new(type, size_t items)
//| - type  : variable or type used as size reference as in sizeof()
//| - items : initial number of items allocated in the array
//| - returns 1 or 0 as success.
//|
//| If you can vaguely estimate the minimal of items, it is good
//| to use this value as it can avoid excessive internal callings to
//| realloc.
*/
#define wArr_new(t,l) \
  _wArr_new(sizeof(t),(size_t)(l))


/*
//$ size_t wArr_len(void *array)
//| Get the length of array, i.e., the used items.
*/
#define wArr_len(a) ((void)NULL,_wArr_len(a))

/*
//$ size_t wArr_cap(void *array)
//| How much length is allocated independent of how much
//| is already used?
*/
#define wArr_cap(a) ((void)NULL,_wArr_cap(a))

#define _wArr_len(a)  (*(((size_t *)(a)) - 3))
#define _wArr_cap(a)  (*(((size_t *)(a)) - 2))
#define _wArr_tsz(a)  (*(((size_t *)(a)) - 1))

/*
//$ int wArr_capsz(void* array, size_t items)
//|
//| Check if there is room for new `items` on `array` or try to allocate
//| the needed space. Returns 1 in success (if there is space or it could be
//| allocated) or 0 on error.
//|
//| On case of error, the error can be retrieved with errno/strerror
*/
#define wArr_capsz(a,c) \
  _wArr_capsz((void *)&(a),(size_t)(c))

/*
//$ int wArr_push(void *array, value)
//|
//| Adds `value` at the end of `array`.
//| Return 1 on success or 0 on fail. In such case the error can be retrieved
//| from the standard C `errno`
*/
#define wArr_push(a,v) ( \
  _wArr_len(a)+1 <= _wArr_cap(a) || wArr_capsz((a),1) \
    ? ((a)[_wArr_len(a)++]=(v),1) : 0 \
)

/*
//$ T wArr_pop(*T, default)
//|
//| Pops the last item of `array`, reducing its length. If the length of array
//| is already 0 returns the specified `default` value.
*/
#define wArr_pop(a,default) ( \
  _wArr_len(a) > 0 \
    ? (a)[(--_wArr_len(a))] \
    : (default) \
)

/*
//$ void wArr_free(*T)
//|
//| If *T is not NULL Free the array, otherwise do nothing.
//| No risk of double free error.
*/
#define wArr_free(a) ( \
  (a) == NULL ? NULL : ( free((size_t *)(a)-3), ((a)=NULL) ) \
)

/*
//$ void wArr_clear(void *array)
//| Reset the array length to 0 without reallocate memory. Further calls to
//| array operation will reuse the allocated memory.
//| Useful to reuse the already allocated memory with different values
//| allowing for less operations.
//|
//| Don't mistake it by the free operation. After you end to use the array
//| you still need to call `wArr_free()'.
*/
#define wArr_clear(a) ( \
  (_wArr_len(a) = 0)    \
)

/*************\
** INTERNALS **
\*************/

static void *_wArr_new(size_t sz, size_t l) {
  size_t *a = realloc(NULL, (sz*l) + sizeof(size_t) * 3);

  if (a == NULL) return NULL;

  a[0]=0;
  a[1]=l;
  a[2]=sz;
  return (void *) (((size_t *)a)+3);
}

#define _c8l_wArr_CALCSZ \
  ((size_t *)(*a)) - 3,(sizeof(size_t) * 3) + (nc * _wArr_tsz(*a))

static int _wArr_capsz (void **a, size_t mincap) {
  size_t *new;
  size_t nc = _wArr_cap(*a);

  mincap += _wArr_len(*a);
  while( (nc *= 2) < mincap );

  if (NULL == (new = realloc(_c8l_wArr_CALCSZ))) return 0;

  *a = (void *) (new+3);
  _wArr_cap(*a) = nc;

  return 1;
}

#endif /* WAX_ARR_INCLUDED */
