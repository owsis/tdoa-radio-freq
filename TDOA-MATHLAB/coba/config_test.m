%% Config File for TDOA setup

% RX and Ref TX Position
rx3_lat = -7.3572570; % RX 3 Bu Rini
rx3_long = 112.6770160;

rx2_lat = -7.3208236; % RX 2 Pak Tri Budi
rx2_long = 112.7002837;

rx1_lat = -7.2774382; % RX 1 PENS
rx1_long = 112.7930353;

%tx_ref_lat = -7.28888888888889; % Referensi TVRI
%tx_ref_long = 112.714166666667;

% tx_ref_lat = -7.2875 ; % Referensi SS
% tx_ref_long = 112.6955556;

tx_ref_lat = -7.2885674 ; % Referensi Radio SS titik gmaps 1000
tx_ref_long = 112.6993234;
% tx_ref_lat = -7.3200864; % Referensi Radio Gen FM titik gmaps 1031
% tx_ref_long = 112.7312756;
% tx_ref_lat = -7.2902441; % Referensi TVRI titik gmaps 5860
% tx_ref_long = 112.7139568;
% tx_ref_lat = -7.3250054; % Referensi 933
% tx_ref_long = 112.7380274;
% tx_ref_lat = -7.3200864; % Referensi 1031
% tx_ref_long = 112.7312756;

% tx_cari_lat = -7.3250054; % cari el-victor 933
% tx_cari_long = 112.7380274;
% tx_cari_lat = -7.3200864; % cari Gen FM 1031
% tx_cari_long = 112.7312756;

tx_cari_lat = -7.2816454; % cari Radio Suara Muslim 938
tx_cari_long = 112.7461872;
% tx_cari_lat = -7.2755979; % cari Radio Sonora 980
% tx_cari_long = 112.6846293;
% tx_cari_lat = -7.2734006; % cari Radio EBS 1059
% tx_cari_long = 112.7490406;

center_point_lat = -7.27513819; % center point
center_point_long = 112.7263886; % center point


% IQ Data Files
%file_identifier = 'test.dat';
file_identifier = '1000_938_2025_7_31_9_26.dat';

folder_identifier = 'data-juli25/';


% signal processing parameters
%signal_bandwidth_khz = 0;  % 400, 200, 40, 12, 0(no)
signal_bandwidth_khz = 40;  % 400, 200, 40, 12, 0(no)
smoothing_factor = 0;
% smoothing_factor = 3;

%corr_type = 'dphase';  %'abs' or 'dphase'
corr_type = 'dphase';  %'abs' or 'dphase'
interpol_factor = 0;

% additional processing of ref signal
%(set to > 0 only when other signals than the ref signal falls into the full RX bandwidth)
ref_bandwidth_khz = 40; % 400, 200, 40, 12, 0(no)
smoothing_factor_ref = 0;
% smoothing_factor_ref = 3;

% 0: no plots
% 1: show correlation plots
% 2: show also input spcetrograms and spectra of input meas
% 3: show also before and after filtering
report_level = 0;

% map output
% 'open_street_map' (default) or 'google_maps'
map_mode = 'open_street_map';

% heatmap (only with google maps)
heatmap_resolution = 200; % resolution for heatmap points
heatmap_threshold = 0.70;  % heatmap point with lower mag are suppressed for html output