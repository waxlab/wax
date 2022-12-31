#include "../arr.h"
#include <assert.h>


static int test_push() {
  int i = 0;
  int *num = t8l_arrnew(*num,2);
  char **str = t8l_arrnew(*str,2);
  num[0]=10;
  num[1]=20;


  for (i=0; i<20; i++) t8l_arrpush(num, i);
  assert(t8l_arrcap(num) == 32); /* on 64 bits where int are 4 bits */
  assert(t8l_arrlen(num) == 20);
  assert(num[19] == 19);


  while(t8l_arrlen(num) > 0) t8l_arrpop(num,-1);
  assert(t8l_arrlen(num) == 0);
  assert(t8l_arrcap(num) == 32);

  t8l_arrcapsz(num,100);
  assert(t8l_arrcap(num) >= 100);

  t8l_arrfree(num);
  assert(num == NULL);
  t8l_arrfree(num); /* no risk for double free */

  t8l_arrpush(str, "olá mundo");
  t8l_arrpush(str, "como vai?");
  t8l_arrpush(str, "terceira linha!");
  t8l_arrpush(str, "será que funfa?");
  t8l_arrpush(str, "será que funfas?");

  printf("%s | %s | %s | %s | Total: %lu\n",str[0],str[1],str[2],str[3],t8l_arrlen(str));

  return 0;
}


int main() {
  test_push();
  return 0;
}

/* vim: set fdm=indent fdn=1 ts=2 sts=2 sw=2: */
