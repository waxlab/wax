// C8L Library - (c) 2022 Thadeu de Paula
// Licensed under MIT Licence.

//| Dynamic Heap Arrays
//|
//| This library provides functions and function like algoriths to
//| create, manage and free dynamic arrays with C.
//|
//| It basically allocates memory for a 3 size_t array plus the amount
//| requested in operations for any specified type.
//|
//| So if you want an array of 5 chars (a string!):
//|
//|             |
//| | 0 | 1 | 2 | 0 | 1 | 2 | 3 | 4 |
//| < meta data | space to store your
//|   in size_t |    data (char *)
//|             |
//|  Hidden     | Exposed to your app
//|

#include <stdio.h>
#include <stdlib.h>
#ifndef C8L_ARR_INCLUDED
#define C8L_ARR_INCLUDED

//$ c8l_arrnew(ref_type, items) : ptr | NULL
//| - ref_type : the variable or type used as size reference as in sizeof()
//| - items    : initial number of items allocated in the array
//| - returns 1 or 0 as success.
//|
//| If you can vaguely estimate the minimal of items, it is good
//| to use this value as it can avoid excessive internal callings to
//| realloc.
#define c8l_arrnew(t,l) \
	_c8l_arrnew(sizeof(t),(size_t)(l))


//$ size_t c8l_arrlen(array)
//| Get the length of array, i.e., the used items.
#define c8l_arrlen(a) ((void)NULL,_c8l_arrlen(a))

//$ size_t c8l_arrcap(array)
//| How much length is allocated independent of how much
//| is already used?
#define c8l_arrcap(a) ((void)NULL,_c8l_arrcap(a))

#define _c8l_arrlen(a)  (*(((size_t *)(a)) - 3))
#define _c8l_arrcap(a)  (*(((size_t *)(a)) - 2))
#define _c8l_arrtsz(a)  (*(((size_t *)(a)) - 1))

//$ int c8l_arrcapsz(*T, size_t items)
//|
//| Check if there is room for new `items` on `array` or try to allocate
//| the needed space. Returns 1 in success (if there is space or it could be
//| allocated) or 0 on error.
//|
//| On case of error, the error can be retrieved with errno/strerror
#define c8l_arrcapsz(a,c) \
	_c8l_arrcapsz((void *)&(a),(size_t)(c))

//$ int c8l_arrpush(*T, value)
//|
//| Adds `value` at the end of `array`.
//| Return 1 on success or 0 on fail. In such case the error can be retrieved
//| from the standard C `errno`
#define c8l_arrpush(a,v) ( \
	_c8l_arrlen(a)+1 <= _c8l_arrcap(a) || c8l_arrcapsz((a),1) \
		? ((a)[_c8l_arrlen(a)++]=(v),1) : 0 \
)

//$ T c8l_arrpop(*T, default)
//|
//| Pops the last item of `array`, reducing its length. If the length of array
//| is already 0 returns the specified `default` value.
#define c8l_arrpop(a,default) ( \
	_c8l_arrlen(a) > 0 \
		? (a)[(--_c8l_arrlen(a))] \
		: (default) \
)

//$ void c8l_arrfree(*T)
//|
//| If *T is not NULL Free the array, otherwise do nothing.
//| No risk of double free error.
#define c8l_arrfree(a) ( \
	(a) == NULL ? NULL : ( free((size_t *)(a)-3), ((a)=NULL) ) \
)

//$ void c8l_arrclear(*T)
//| Reset the array length to 0 without reallocate memory. Further calls to
//| array operation will reuse the allocated memory.
//| Useful to reuse the already allocated memory with different values
//| allowing for less operations.
//|
//| Don't mistake it by the free operation. After you end to use the array
//| you still need to call `c8l_arrfree()'.
#define c8l_arrclear(a) ( \
	(_c8l_arrlen(a) = 0)    \
)


static void *_c8l_arrnew(size_t sz, size_t l) {
	size_t *a = realloc(NULL, (sz*l) + sizeof(size_t) * 3);

	if (a == NULL) return NULL;

	a[0]=0;
	a[1]=l;
	a[2]=sz;
	return (void *) (((size_t *)a)+3);
}

#define _c8l_arr_CALCSZ \
	((size_t *)(*a)) - 3,(sizeof(size_t) * 3) + (nc * _c8l_arrtsz(*a))

static int _c8l_arrcapsz (void **a, size_t mincap) {
	size_t *new;
	size_t nc = _c8l_arrcap(*a);

	mincap += _c8l_arrlen(*a);
	while( (nc *= 2) < mincap );

	if (NULL == (new = realloc(_c8l_arr_CALCSZ))) return 0;

	*a = (void *) (new+3);
	_c8l_arrcap(*a) = nc;

	return 1;
}

#endif /* C8L_ARR_INCLUDED */
