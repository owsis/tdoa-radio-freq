%% Config File for TDOA setup

% RX and Ref TX Position
rx3_lat = -7.31583333333333 ; % RX 3
rx3_long = 112.701666666667;

rx2_lat = -7.35472222222222; % RX 2
rx2_long = 112.676666666667;

rx1_lat = -7.30111111111111; % RX 1
rx1_long = 112.782777777778;

tx_ref_lat = -7.28888888888889; % Referensi TVRI
tx_ref_long = 112.714166666667;

%tx_ref_lat = -7.2875 ; % Referensi SS
%tx_ref_long = 112.6955556;

% IQ Data Files
%file_identifier = 'test.dat';
file_identifier = '1031_933_2024_5_23_13_22.dat';

folder_identifier = 'recorded_data/';


% signal processing parameters
%signal_bandwidth_khz = 0;  % 400, 200, 40, 12, 0(no)
signal_bandwidth_khz = 0;  % 400, 200, 40, 12, 0(no)
%smoothing_factor = 0;
smoothing_factor = 12;

%corr_type = 'dphase';  %'abs' or 'dphase'
corr_type = 'abs';  %'abs' or 'dphase'
interpol_factor = 0;

% additional processing of ref signal
%(set to > 0 only when other signals than the ref signal falls into the full RX bandwidth)
ref_bandwidth_khz = 12; % 400, 200, 40, 12, 0(no)
%smoothing_factor_ref = 0;
smoothing_factor_ref = 12;

% 0: no plots
% 1: show correlation plots
% 2: show also input spcetrograms and spectra of input meas
% 3: show also before and after filtering
report_level = 2;

% map output
% 'open_street_map' (default) or 'google_maps'
map_mode = 'open_street_map';

% heatmap (only with google maps)
heatmap_resolution = 400; % resolution for heatmap points
heatmap_threshold = 0.1;  % heatmap point with lower mag are suppressed for html output