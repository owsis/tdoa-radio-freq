#include "FilterIQ.hpp"

int FilterIQ(std::vector<unsigned char> signal_iq, unsigned int signal_bandwidth_khz)
{
  unsigned int Fs = 2000;            // Sampling Frequency
  unsigned short Fpass, Fstop, dens; // Passband, Stopband Frequency & Density Factor
  float Dpass, Dstop;                // Passband Ripple & Stopband Attenuation

  switch (signal_bandwidth_khz)
  {
  case 400:
    Fpass = 200;
    Fstop = 300;
    Dpass = 0.0057563991496;
    Dstop = 0.001;
    dens = 20;

    break;

  case 200:
    Fpass = 100;
    Fstop = 150;
    Dpass = 0.028774368332;
    Dstop = 0.001;
    dens = 20;
    break;

  case 40:
    Fpass = 20;
    Fstop = 100;
    Dpass = 0.0057563991496;
    Dstop = 0.001;
    dens = 20;
    break;

  case 12:
    Fpass = 6.25;
    Fstop = 50;
    Dpass = 0.028774368332;
    Dstop = 0.001;
    dens = 20;
    break;

  case 0:
    std::cout << "Signal Not Filtered";
    break;

  default:
    break;
  }
}

// Fungsi untuk menghitung urutan filter FIR berdasarkan metode firpmord
void firpmord(const std::vector<double> &f, const std::vector<double> &a, const std::vector<double> &dev, double fs, int &N, std::vector<double> &fo, std::vector<double> &ao, std::vector<double> &w)
{
  // Konstanta
  const double delta_f = f[1] - f[0]; // Perbedaan frekuensi cutoff
  const double d1 = dev[0];           // Deviasi untuk passband
  const double d2 = dev[1];           // Deviasi untuk stopband

  // Hitung urutan filter berdasarkan rumus perkiraan
  N = static_cast<int>(ceil((-20 * log10(sqrt(d1 * d2)) - 13) / (14.6 * delta_f)));

  // Menyesuaikan fo, ao, dan w sesuai masukan
  fo = f;
  ao = a;

  // Bobot
  w.push_back(dev[0] / dev[1]);
}
