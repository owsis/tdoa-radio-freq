#ifndef READ_IQ_H
#define READ_IQ_H

#include <vector>
#include <string>
#include <complex>

int ReadIQ(const std::string &filename, std::vector<std::complex<float>> &iqSignal);

#endif