/*
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright 2022-2023 - Thadeu de Paula and contributors
*/
#include "../arr.h"
#include <assert.h>
#include <string.h>
#include <errno.h>


static int test_push() {
  int i = 0;
  int *num = wArr_new(*num,2);
  char **str = wArr_new(*str,2);

  if (num != NULL) {
    num[0]=10;
    num[1]=20;

    for (i=0; i<20; i++) wArr_push(num, i);
    assert(wArr_len(num) == 20);
    assert(num[19] == 19);


    while(wArr_len(num) > 0) wArr_pop(num,-1);
    assert(wArr_len(num) == 0);

    wArr_capsz(num,100);
    assert(wArr_cap(num) >= 100);

    wArr_free(num);
    assert(num == NULL);
    wArr_free(num); /* no risk for double free */

  } else {
    printf("Error for num: %s\n",strerror(errno));
  }

  if (str != NULL) {
    wArr_push(str, "olá mundo");
    wArr_push(str, "como vai?");
    wArr_push(str, "terceira linha!");
    wArr_push(str, "será que funfa?");
    wArr_push(str, "será que funfas?");

    printf("%s | %s | %s | %s | Total: %lu\n",str[0],str[1],str[2],str[3],wArr_len(str));

  } else {
    printf("Error for str: %s\n", strerror(errno));
  }

  return 0;
}


int main() {
  test_push();
  return 0;
}

