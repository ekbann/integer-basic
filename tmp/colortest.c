#include <stdio.h>
#include <stdlib.h>

int main(void)
{
  __asm__("lda #$00");
  __asm__("sta $d020");

  *(char*)0xd021=2;

  return EXIT_SUCCESS;
}
