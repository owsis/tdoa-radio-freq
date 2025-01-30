#include <iostream>
#include <fstream>
#include "ReadIQ.h"

int ReadIQ(const std::string &filename, std::vector<std::complex<float>> &iqSignal)
{
  std::cout << "read_file_iq" << std::endl;
  std::cout << "IQ read from data file = " << filename << std::endl;

  // Membuka file biner untuk membaca data
  std::ifstream file(filename, std::ios::binary);
  if (!file.is_open())
  {
    std::cerr << "Error: File tidak dapat dibuka!" << std::endl;
    return 1;
  }

  // Membaca seluruh isi file
  std::vector<uint8_t> data((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
  file.close();

  // Memastikan ukuran array sesuai dengan pasangan I dan Q
  if (data.size() % 2 != 0)
  {
    std::cerr << "Error: Ukuran file tidak valid (harus genap untuk pasangan IQ)." << std::endl;
    return 1;
  }

  // Inisialisasi vektor untuk menyimpan sinyal kompleks IQ
  size_t num_samples = data.size() / 2;

  // Parsing data menjadi in-phase (I) dan quadrature (Q)
  for (size_t i = 0; i < num_samples; ++i)
  {
    float inphase = static_cast<float>(data[2 * i]) - 128.0f;
    float quadrature = static_cast<float>(data[2 * i + 1]) - 128.0f;
    iqSignal.emplace_back(inphase, quadrature); // Menggabungkan I dan Q menjadi kompleks
  }

  std::cout << "successfully read " << num_samples << " samples" << std::endl;
  return 0;
}
