#include <stdio.h>
#include <stdlib.h>

int main(int argc, char const *argv[])
{
  if (argc < 3)
  {
    printf("Usage: %s --freq <frequency> \n", argv[0]);
    return 1;
  }

  int freq = atoi(argv[2]) * 100000; // ex: 100000000
  char mrekam[200];
  sprintf(mrekam, "rtl_fm -f %d -select -M wbfm -s 480K -g 30 -r 24K | aplay -c 1 -t raw -f S16_LE -r 24000", freq);

  printf("%s\n", mrekam);
  // system(mrekam);
  return 0;
}
