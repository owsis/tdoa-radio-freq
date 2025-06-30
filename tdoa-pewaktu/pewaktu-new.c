#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>
#include <time.h>

int main(int argc, char const *argv[])
{
  if (argc < 7)
  {
    printf("Usage: %s --fref <frequency> --fcari <frequency> --loop <iterate> \n", argv[0]);
    return 1;
  }

  int i, j;
  int err;
  char namafile[100];
  clock_t t0;
  float tdecimasi = 0.0;

  int ff = atoi(argv[2]) * 100000; /* Emisi referensi */
  int hh = atoi(argv[4]) * 100000; /* Emisi yg dicari */

  char mrekam[200];
  int receiver = 3; /*Siswo=1; Irsyad=2; Juned=3 */
  // sprintf(mrekam, "./rtl_sdr -f %d -h %d -n 1.2e6 ", ff, hh);
  //    sprintf(mrekam,"./rtl_sdr -f 586e6 -h 103.1e6 -n 1.2e6 ");

  // Menunggu waktu menit genab

  time_t t = time(NULL);
  struct tm tm = *localtime(&t);
  while (tm.tm_min % 2 == 0)
  {
    printf("sekarang == 0: %d-%d-%d %d:%d:%d\n", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
    t = time(NULL);
    tm = *localtime(&t);
    //  sleep(1);
    //  system("clear");
  }
  // while (tm.tm_min % 2 == 1)
  // {
  //   // printf("sekarang == 1: %d-%d-%d %d:%d:%d\n", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
  //   t = time(NULL);
  //   tm = *localtime(&t);
  //   //  sleep(1);
  //   //  system("clear");
  //   if (tm.tm_min % 2 == 0)
  //   {
  //     //    sprintf(namafile,"%d_%d_%d_%d_%d_%d.dat\n", receiver,tm.tm_year+1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min);
  //     sprintf(namafile, "%d_%d_%d_%d_%d_%d_%d_%d.dat\n", receiver, ff / 100000, hh / 100000, tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min);

  //     strcat(mrekam, namafile);
  //   }
  // }
  for (size_t i = 0; i < atoi(argv[6]); i++)
  {
    while (tm.tm_sec != 0)
    {
      // update waktu per seconds
      t = time(NULL);
      tm = *localtime(&t);

      if (tm.tm_sec == 0)
      {
        sprintf(mrekam, "./rtl_sdr -f %d -h %d -n 1.2e6 ", ff, hh);
        sprintf(namafile, "%d_%d_%d_%d_%d_%d_%d_%d.dat\n", receiver, ff / 100000, hh / 100000, tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min);
        strcat(mrekam, namafile);
      }
    }

    printf("%s\n", mrekam);
    // system(mrekam);
    sleep(10);

    // update waktu per seconds
    t = time(NULL);
    tm = *localtime(&t);
  }
}
