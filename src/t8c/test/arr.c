#include "../arr.h"
#include <assert.h>


static int test_push() {
  int i = 0;
  int *num = t8c_arrnew(*num,2);
  char **str = t8c_arrnew(*str,2);
  num[0]=10;
  num[1]=20;


  for (i=0; i<20; i++) t8c_arrpush(num, i);
  assert(t8c_arr(num)->cap == 32); /* on 64 bits where int are 4 bits */
  assert(t8c_arr(num)->len == 20);
  assert(num[19] == 19);


  while(t8c_arr(num)->len) t8c_arrpop(num,-1);
  assert(t8c_arr(num)->len == 0);
  assert(t8c_arr(num)->cap == 32);

  t8c_arrcapsz(num,100);
  assert(t8c_arr(num)->cap >= 100);

  t8c_arrfree(num);
  assert(num == NULL);
  t8c_arrfree(num); /* no risk for double free */

  t8c_arrpush(str, "olá mundo");
  t8c_arrpush(str, "como vai?");
  t8c_arrpush(str, "terceira linha!");
  t8c_arrpush(str, "será que funfa?");
  t8c_arrpush(str, "será que funfas?");

  printf("%s | %s | %s | %s | Total: %lu\n",str[0],str[1],str[2],str[3],t8c_arr(str)->len);

  return 0;
}


int main() {
  test_push();
  return 0;
}
