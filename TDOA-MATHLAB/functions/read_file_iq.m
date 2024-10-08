function [ iq_signal ] = read_file_iq( filename )
%read_file_tdoa reads a file with IQ data (e.g. from rtl_sdr)

    disp('read_file_iq');

    % daten vom 1. RX
    disp(['IQ read from data file = ' filename]);
    fileID = fopen(filename);
    a = fread(fileID);
    fclose(fileID);

    % Membaca array a dimulai dari '1' sampai 'end' dengan ketentuan loncat '2' nilai,
    % yang berarti hanya nomor ganjil yang akan dioperasikan, ex: [1, 3, 5, ...]
    % Kemudian setiap nilai akan dikurangi '-128'
    inphase1 = a(1:2:end) -128;

    % Membaca array a dimulai dari '2' sampai 'end' dengan ketentuan loncat '2' nilai,
    % yang berarti hanya nomor ganjil yang akan dioperasikan, ex: [2, 4, 6, ...]
    % Kemudian setiap nilai akan dikurangi '-128'
    quadrature1 = a(2:2:end) -128;
    disp(['successfully read ' int2str(length(inphase1)) ' samples']);

    % complex representation
    % 1i = representasi dari bilangan imajiner, yaitu √(-1)
    % 1i.*quadrature1 => berarti mengalikan setiap elemen dari quadrature1 dengan 1i
    % inphase1 + 1i.*quadrature1 => penjumlahan 2 array, ex: 1.1234+0.1234i
    iq_signal = inphase1 + 1i.*quadrature1;

end

