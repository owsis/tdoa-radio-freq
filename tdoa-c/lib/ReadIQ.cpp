#include "ReadIQ.hpp"

int ReadIQ(std::string filename)
{
  // Membuka file dalam mode biner, dan langsung ke akhir file
  std::ifstream file(filename, std::ios::binary | std::ios::ate);
  if (!file.is_open())
  {
    std::cerr << "Error opening file" << std::endl;
    return 1;
  }

  // Mendapatkan ukuran file
  std::streamsize fileSize = file.tellg(); // Mendapatkan ukuran file dengan posisi saat ini (akhir file)
  file.seekg(0, std::ios::beg);            // Kembali ke awal file

  // Membuat buffer sesuai dengan ukuran file
  std::vector<unsigned char> buffer(fileSize);

  // Membaca isi file ke dalam buffer
  if (!file.read(reinterpret_cast<char *>(buffer.data()), fileSize))
  {
    std::cerr << "Error reading file" << std::endl;
    return 1;
  }

  // Menutup file
  file.close();

  // Membuat dua vector untuk menampung data inphase dan quadrature
  std::vector<int> inphase;
  std::vector<int> quadrature;

  // Proses data: ambil data dari indeks inphase dan quadrature, kurangi 128, lalu masukkan ke vector
  for (size_t i = 0; i < buffer.size(); i += 2)           // Mengambil data dari indeks inphase
    inphase.push_back(static_cast<int>(buffer[i]) - 128); // Kurangi 128 dan tambahkan ke vector

  for (size_t i = 1; i < buffer.size(); i += 2)              // Mengambil data dari indeks quadrature
    quadrature.push_back(static_cast<int>(buffer[i]) - 128); // Kurangi 128 dan tambahkan ke vector

  // Menentukan ukuran array kompleks (gunakan ukuran terkecil antara inphase dan quadrature)
  size_t complexArraySize = std::min(inphase.size(), quadrature.size());

  // Membuat array bilangan kompleks
  std::vector<std::complex<int> > complexArray(complexArraySize);

  // Mengisi array bilangan kompleks dengan nilai dari vektor inphase (real) dan quadrature (imajiner)
  for (size_t i = 0; i < complexArraySize; ++i)
    complexArray[i] = std::complex<int>(inphase[i], quadrature[i]); // Membuat bilangan kompleks dengan inphase sebagai real dan quadrature sebagai imajiner

  // Menampilkan ukuran array bilangan kompleks
  std::cout << "Ukuran array bilangan kompleks: " << complexArray.size() << std::endl;

  // Contoh menampilkan beberapa bilangan kompleks
  std::cout << "Contoh bilangan kompleks: " << std::endl;
  for (size_t i = 0; i < std::min(complexArray.size(), size_t(10)); ++i)
    std::cout << complexArray[i] << std::endl; // Menampilkan 10 bilangan kompleks pertama

  return 0;
}
