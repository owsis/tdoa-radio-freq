#ifndef FILTER_IQ_H
#define FILTER_IQ_H

#include <iostream>
#include <cmath>
#include <vector>
#include <complex>

int FilterIQ(std::vector<unsigned char> signal_iq, unsigned int signal_bandwidth_khz);
void firpmord(const std::vector<double> &f, const std::vector<double> &a, const std::vector<double> &dev, double fs, int &N, std::vector<double> &fo, std::vector<double> &ao, std::vector<double> &w);

#endif