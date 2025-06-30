
#! /bin/bash

# dari buku RTL-SDR
# ini paling mantab...
rtl_fm -f 88100000 -select -M wbfm -s 480K -g 30 -r 24K | aplay -c 1 -t raw -f S16_LE -r 24000

# ini tunggu upconverter dulu
# ini paling mantab... 29 Agt 2020
# juga bisa di pita 40M

#rtl_fm -f 126152000 -F 4 -M am -s 480K -g 10 -r 24000 | \
#rtl_fm -f 126116000 -F 4 -M am -s 480K -g 10 -r 24000 | \
#rtl_fm -f 126062000 -F 4 -M am -s 480K -g 10 -r 24000 | \
#rtl_fm -f 125585000 -F 5 -M am -s 480K -g 20 -r 24000 | \
#rtl_fm -f 126278000 -F 5 -M am -s 480K -g 10 -r 24000 | \          
#rtl_fm -f 125585000 -F 5 -M am -s 480K -g 10 -r 24000 | \
#baca Quran
#rtl_fm -f 125842000 -F 5 -M am -s 480K -g 10 -r 24000 | \  

#rtl_fm -f 132100000 -F 6 -M lsb -s 480K -g 30 -r 24000 | \
#	aplay -t raw -r 24000 -f s16_LE -c 1

