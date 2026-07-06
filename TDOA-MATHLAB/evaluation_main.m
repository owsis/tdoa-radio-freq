function evaluation_main(varargin)
% =========================================================================
%  Experimental Evaluation Script for RTL-SDR based TDOA
%  DC9ST, 2017-2019
% =========================================================================
%
% Usage:
%   evaluation_main()                          % uses default config
%   evaluation_main('filename.dat')           % uses specified file
%   evaluation_main('--file', 'filename.dat') % alternative syntax
%
% Examples:
%   evaluation_main('933_1031_2025_6_12_9_21.dat')
%   evaluation_main('--file', '933_1031_2025_6_12_9_21.dat')

% Parse input arguments
if nargin == 0
    % No arguments, use default config
    file_override = '';
elseif nargin == 1
    % Single argument - assume it's a filename
    file_override = varargin{1};
elseif nargin == 2 && strcmp(varargin{1}, '--file')
    % Two arguments with --file flag
    file_override = varargin{2};
else
    error('Invalid arguments. Usage: evaluation_main() or evaluation_main(''filename.dat'') or evaluation_main(''--file'', ''filename.dat'')');
end

disp(['file override: ' file_override]);

% adds subfolder with functions to PATH
[p,~,~] = fileparts(mfilename('fullpath'));
addpath([p '/functions']);
%addpath([p '/test']); % only required for the test setups
addpath([p '/coba']); % only required for the test setups


%% Config for TDOA setup

% RX and Ref TX Position
rx3_lat = -7.3572570; % RX 3 Bu Rini
rx3_long = 112.6770160;

rx2_lat = -7.2774382; % RX 2 Pak Tri Budi
rx2_long = 112.7930353;

rx1_lat = -7.22795569; % RX 1 Sontoh Laut -7.22795569, 112.68459984
rx1_long = 112.68459984;

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

% IMPROVEMENT: Use improved heatmap generation
% Set to true to use adaptive weighted heatmap with outlier rejection
use_improved_heatmap = false;  % Toggle: true = improved, false = original
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Override file_identifier if provided as argument
if ~isempty(file_override)
    disp(['Overriding config file_identifier with: ' file_override]);
    file_identifier = file_override;
else
    disp(['Using file from config: ' file_override]);
end

% base folder
folder_identifier = 'data-november/';
folder_result = 'data-nov-hasil/';

% create filenames
dateiname1 = [folder_identifier '1_' file_identifier];
dateiname2 = [folder_identifier '2_' file_identifier];
dateiname3 = [folder_identifier '3_' file_identifier];

% calculate geodetic reference point as mean center of all RX positions
geo_ref_lat  = mean([rx1_lat, rx2_lat, rx3_lat]);
geo_ref_long = mean([rx1_long, rx2_long, rx3_long]);
disp(['geodetic reference point (mean of RX positions): lat=' num2str(geo_ref_lat, 8) ', long=' num2str(geo_ref_long, 8) ])

% known signal path differences between two RXes to Ref (sign of result is important!)
rx_distance_diff12 = dist_latlong(tx_ref_lat, tx_ref_long, rx1_lat, rx1_long, geo_ref_lat, geo_ref_long) - dist_latlong(tx_ref_lat, tx_ref_long, rx2_lat, rx2_long, geo_ref_lat, geo_ref_long); % (Ref to RX1 - Ref to RX2) in meters
rx_distance_diff13 = dist_latlong(tx_ref_lat, tx_ref_long, rx1_lat, rx1_long, geo_ref_lat, geo_ref_long) - dist_latlong(tx_ref_lat, tx_ref_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long); % (Ref to RX1 - Ref to RX3) in meters
rx_distance_diff23 = dist_latlong(tx_ref_lat, tx_ref_long, rx2_lat, rx2_long, geo_ref_lat, geo_ref_long) - dist_latlong(tx_ref_lat, tx_ref_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long); % (Ref to RX2 - Ref to RX3) in meters

% distance between two RXes in meters
rx_distance12 = dist_latlong(rx1_lat, rx1_long, rx2_lat, rx2_long, geo_ref_lat, geo_ref_long);
rx_distance13 = dist_latlong(rx1_lat, rx1_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long);
rx_distance23 = dist_latlong(rx2_lat, rx2_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long);

%% Read Signals from File
disp('______________________________________________________________________________________________');
disp('READ DATA FROM FILES');
signal1 = read_file_iq(dateiname1);
signal2 = read_file_iq(dateiname2);
signal3 = read_file_iq(dateiname3);

if (report_level > 1)
    % display raw signals
    num_samples_total = length(signal1);
    inphase1 = real(signal1);
    quadrature1 = imag(signal1);
    inphase2 = real(signal2);
    quadrature2 = imag(signal2);
    inphase3 = real(signal3);
    quadrature3 = imag(signal3);
    
    figure;
    subplot(3,1,1);
    plot(1:num_samples_total, inphase1(1:num_samples_total), 1:num_samples_total, quadrature1(1:num_samples_total));
    title('raw RX 1: I and Q');
    subplot(3,1,2);
    plot(1:num_samples_total, inphase2(1:num_samples_total), 1:num_samples_total, quadrature2(1:num_samples_total));
    title('raw RX 2: I and Q');
    subplot(3,1,3);
    plot(1:num_samples_total, inphase3(1:num_samples_total), 1:num_samples_total, quadrature3(1:num_samples_total));
    title('raw RX 3: I and Q');
    % return;
end

% if (report_level > 1)
%     % calculate and show spectrogram
%     nfft = 256;
%     overlap = 8;

%     figure;
%     subplot(4,2,1);
%     complex_signal = detrend(signal1);
%     [S,F,T,P] = spectrogram(complex_signal, nfft, overlap, nfft, 2e6 );
%     spectrum = fftshift(fliplr(10*log10(abs(P))'), 2);
%     for i=1:nfft
%         spectrum(:,i) = smooth(spectrum(:,i),9);
%     end
%     surf(T,F, spectrum', 'edgecolor', 'none');
%     axis tight;
%     view(0,90);
%     title('RX 1');
%     xlabel('time');
%     ylabel('frequency');

%     subplot(4,2,3);
%     complex_signal = detrend(signal2);
%     [S,F,T,P] = spectrogram(complex_signal, nfft, overlap, nfft, 2e6 );
%     spectrum = fftshift(fliplr(10*log10(abs(P))'), 2);
%     for i=1:nfft
%         spectrum(:,i) = smooth(spectrum(:,i),9);
%     end
%     surf(T,F, spectrum', 'edgecolor', 'none');
%     axis tight;
%     view(0,90);
%     title('RX 2');
%     xlabel('time');
%     ylabel('frequency');


%     subplot(4,2,5);
%     complex_signal = detrend(signal3);
%     [S,F,T,P] = spectrogram(complex_signal, nfft, overlap, nfft, 2e6 );
%     spectrum = fftshift(fliplr(10*log10(abs(P))'), 2);
%     for i=1:nfft
%         spectrum(:,i) = smooth(spectrum(:,i),9);
%     end
%     surf(T,F, spectrum', 'edgecolor', 'none');
%     axis tight;
%     view(0,90);
%     title('RX 3');
%     xlabel('time');
%     ylabel('frequency');

%     % display spectrum
%     spectrum_smooth_factor  = 201;
%     subplot(4,2,2);
%     spectrum_single1 = 10*log10(abs(fftshift(fft(signal1(1.7e6 : 1.7e6 + 2^18)))));
%     spectrum_single1 = smooth(spectrum_single1, spectrum_smooth_factor);
%     plot(spectrum_single1);
%     title('Measurement RX 1');
%     grid;

%     subplot(4,2,4);
%     spectrum_single2 = 10*log10(abs(fftshift(fft(signal2(1.7e6 : 1.7e6 + 2^18)))));
%     spectrum_single2 = smooth(spectrum_single2, spectrum_smooth_factor);
%     plot(spectrum_single2);
%     title('Measurement RX 2');
%     grid;

%     subplot(4,2,6);
%     spectrum_single3 = 10*log10(abs(fftshift(fft(signal3(1.7e6 : 1.7e6 + 2^18)))));
%     spectrum_single3 = smooth(spectrum_single3, spectrum_smooth_factor);
%     plot(spectrum_single3);
%     title('Measurement RX 3');
%     grid;

%     subplot(4,2,7:8);
%     freq_axis = -(length(spectrum_single1)/2) : 1 : ((length(spectrum_single1)/2)-1);
%     plot(freq_axis, spectrum_single1, freq_axis, spectrum_single2, freq_axis, spectrum_single3);
%     title('Measurement Signal RX 1,2 & 3');
%     grid;
% end;



%% Calculate TDOA
disp(' ');
disp('______________________________________________________________________________________________');
disp('CORRELATION 1 & 2');
[doa_meters12, doa_samples12, reliability12, delay_ref_sample12, drift_analysis12] = tdoa2(signal1, signal2, rx_distance_diff12, rx_distance12, ...
    smoothing_factor, corr_type, report_level, signal_bandwidth_khz, ...
    ref_bandwidth_khz, smoothing_factor_ref, interpol_factor);

disp(' ');
disp('______________________________________________________________________________________________');
disp('CORRELATION 1 & 3');
[doa_meters13, doa_samples13, reliability13, delay_ref_sample13, drift_analysis13] = tdoa2(signal1, signal3, rx_distance_diff13, rx_distance13, ...
    smoothing_factor, corr_type, report_level, signal_bandwidth_khz, ...
    ref_bandwidth_khz, smoothing_factor_ref, interpol_factor);

disp(' ');
disp('______________________________________________________________________________________________');
disp('CORRELATION 2 & 3');
[doa_meters23, doa_samples23, reliability23, delay_ref_sample23, drift_analysis23] = tdoa2(signal2, signal3, rx_distance_diff23, rx_distance23, ...
    smoothing_factor, corr_type, report_level, signal_bandwidth_khz, ...
    ref_bandwidth_khz, smoothing_factor_ref, interpol_factor);


% %% IMPROVEMENT: Check reliability and apply filtering
disp(' ');
disp('______________________________________________________________________________________________');
disp('RELIABILITY ANALYSIS');

% Define reliability threshold (1% minimum untuk dianggap reliable)
RELIABILITY_THRESHOLD = 0.001;
MIN_POINTS_THRESHOLD = 100; % Minimum points untuk hiperbola yang baik

% Display all reliabilities
disp(['Correlation 1 & 2 reliability: ' num2str(reliability12, '%.6f')]);
disp(['Correlation 1 & 3 reliability: ' num2str(reliability13, '%.6f')]);
disp(['Correlation 2 & 3 reliability: ' num2str(reliability23, '%.6f')]);

% Check which correlations are reliable
reliable12 = reliability12 >= RELIABILITY_THRESHOLD;
reliable13 = reliability13 >= RELIABILITY_THRESHOLD;
reliable23 = reliability23 >= RELIABILITY_THRESHOLD;

if ~reliable12
    disp('<strong>WARNING: Correlation 1&2 reliability below threshold!</strong>');
end
if ~reliable13
    disp('<strong>WARNING: Correlation 1&3 reliability below threshold!</strong>');
end
if ~reliable23
    disp('<strong>WARNING: Correlation 2&3 reliability below threshold!</strong>');
end

% Calculate normalized weights for weighted intersection
total_reliability = reliability12 + reliability13 + reliability23;
if total_reliability > 0
    weight12 = reliability12 / total_reliability;
    weight13 = reliability13 / total_reliability;
    weight23 = reliability23 / total_reliability;
else
    % Equal weights if all reliabilities are zero
    weight12 = 1/3;
    weight13 = 1/3;
    weight23 = 1/3;
end

disp(['Normalized weights: 1&2=' num2str(weight12, '%.3f') ', 1&3=' num2str(weight13, '%.3f') ', 2&3=' num2str(weight23, '%.3f')]);

%% ======================================================================
%% FREQUENCY DRIFT SUMMARY REPORT
%% ======================================================================

disp(' ');
disp('______________________________________________________________________________________________');
disp('FREQUENCY DRIFT ANALYSIS RESULTS');
disp('______________________________________________________________________________________________');

% Consolidate drift results from all three correlations
% We'll use the most confident measurement for each interpretation

% Display detailed drift analysis
disp(' ');
disp('PAIRWISE FREQUENCY DRIFT (in PPM):');
disp('───────────────────────────────────');
disp(sprintf('  Pair 1-2 | Drift: %+7.2f ppm | Confidence: %.2f | Warning: %d', ...
    drift_analysis12.ppm_12, drift_analysis12.conf_12, drift_analysis12.warn_12));
disp(sprintf('  Pair 1-3 | Drift: %+7.2f ppm | Confidence: %.2f | Warning: %d', ...
    drift_analysis13.ppm_13, drift_analysis13.conf_13, drift_analysis13.warn_13));
disp(sprintf('  Pair 2-3 | Drift: %+7.2f ppm | Confidence: %.2f | Warning: %d', ...
    drift_analysis23.ppm_23, drift_analysis23.conf_23, drift_analysis23.warn_23));

% Calculate statistics
all_drifts = [drift_analysis12.ppm_12, drift_analysis13.ppm_13, drift_analysis23.ppm_23];
all_confs = [drift_analysis12.conf_12, drift_analysis13.conf_13, drift_analysis23.conf_23];

avg_drift = mean(all_drifts);
max_drift = max(abs(all_drifts));
avg_conf = mean(all_confs);

disp(' ');
disp('DRIFT STATISTICS:');
disp('────────────────');
disp(sprintf('  Average drift:        %+7.2f ppm', avg_drift));
disp(sprintf('  Maximum drift:        %7.2f ppm', max_drift));
disp(sprintf('  Average confidence:   %6.2f', avg_conf));

% Interpretation
if max_drift < 5
    drift_status = '✓ EXCELLENT - No significant clock drift detected';
elseif max_drift < 10
    drift_status = '⚠ GOOD - Minimal clock drift (should not affect accuracy much)';
elseif max_drift < 50
    drift_status = '⚠⚠ CAUTION - Moderate clock drift detected, may affect accuracy';
else
    drift_status = '✗ CRITICAL - Severe frequency drift! Accuracy is significantly degraded!';
end

disp(' ');
disp(sprintf('STATUS: %s', drift_status));

% Recommendations
if max_drift > 10
    disp(' ');
    disp('RECOMMENDATIONS TO IMPROVE ACCURACY:');
    disp('─────────────────────────────────────');
    if max_drift > 50
        disp('  [URGENT] Synchronization Issues:');
        disp('    • Check if NTP is running on all SBC units: ntpstat');
        disp('    • Verify network connectivity and stability');
        disp('    • Check for excessive ping jitter: ping <gateway>');
        disp('  ');
    end
    disp('  Short-term (Software):');
    disp('    • Increase record duration to average out drift');
    disp('    • Use filtered signal bandwidth 40 kHz instead of wider bandwidth');
    disp('  ');
    disp('  Long-term (Hardware):');
    disp('    • Implement GPS-PPS (pulse-per-second) discipline on SBC');
    disp('    • Use external 10 MHz reference oscillator for RTL-SDR units');
    disp('    • Replace RTL-SDR with synchronized multi-channel hardware (USRP)');
end

disp(' ');


%% Generate html map
disp(' ');
disp('______________________________________________________________________________________________');
disp('GENERATE HYPERBOLAS');

% === ORIGINAL CODE (COMMENTED) ===
% [points_lat1, points_long1] = gen_hyperbola(doa_meters12, rx1_lat, rx1_long, rx2_lat, rx2_long, geo_ref_lat, geo_ref_long, 'RX1', 'RX2');
% [points_lat2, points_long2] = gen_hyperbola(doa_meters13, rx1_lat, rx1_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long, 'RX1', 'RX3');
% [points_lat3, points_long3] = gen_hyperbola(doa_meters23, rx2_lat, rx2_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long, 'RX2', 'RX3');

% === IMPROVED CODE ===
% Check if improved function is available
has_improved_func = exist('gen_hyperbola_improved', 'file');
MIN_POINTS_FOR_RETRY = 40; % Minimum points threshold for retrying with improved function

% Generate hyperbola 1 (RX1-RX2)
disp(' ');
disp('--- Hyperbola 1: RX1 & RX2 ---');
if ~reliable12
    disp(['<strong>WARNING: Hyperbola 1 has LOW reliability (' num2str(reliability12, '%.6f') ') below threshold (' num2str(RELIABILITY_THRESHOLD) ')</strong>']);
    disp('Hyperbola will be generated for visualization but given very low weight in intersection calculation.');
end
% First try with standard gen_hyperbola
disp('Using gen_hyperbola (standard)...');
[points_lat1, points_long1] = gen_hyperbola(doa_meters12, rx1_lat, rx1_long, rx2_lat, rx2_long, geo_ref_lat, geo_ref_long, 'RX1', 'RX2');
% Check if points are insufficient, retry with improved version
if length(points_lat1) <= MIN_POINTS_FOR_RETRY && has_improved_func
    disp(['  Points generated: ' num2str(length(points_lat1)) ' <= ' num2str(MIN_POINTS_FOR_RETRY) ', retrying with gen_hyperbola_improved...']);
    [points_lat1, points_long1] = gen_hyperbola_improved(doa_meters12, rx1_lat, rx1_long, rx2_lat, rx2_long, geo_ref_lat, geo_ref_long, 'RX1', 'RX2');
    disp(['  Improved version generated: ' num2str(length(points_lat1)) ' points']);
else
    disp(['  Points generated: ' num2str(length(points_lat1))]);
end

% Generate hyperbola 2 (RX1-RX3)
disp(' ');
disp('--- Hyperbola 2: RX1 & RX3 ---');
if ~reliable13
    disp(['<strong>WARNING: Hyperbola 2 has LOW reliability (' num2str(reliability13, '%.6f') ') below threshold (' num2str(RELIABILITY_THRESHOLD) ')</strong>']);
    disp('Hyperbola will be generated for visualization but given very low weight in intersection calculation.');
end
% First try with standard gen_hyperbola
disp('Using gen_hyperbola (standard)...');
[points_lat2, points_long2] = gen_hyperbola(doa_meters13, rx1_lat, rx1_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long, 'RX1', 'RX3');
% Check if points are insufficient, retry with improved version
if length(points_lat2) <= MIN_POINTS_FOR_RETRY && has_improved_func
    disp(['  Points generated: ' num2str(length(points_lat2)) ' <= ' num2str(MIN_POINTS_FOR_RETRY) ', retrying with gen_hyperbola_improved...']);
    [points_lat2, points_long2] = gen_hyperbola_improved(doa_meters13, rx1_lat, rx1_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long, 'RX1', 'RX3');
    disp(['  Improved version generated: ' num2str(length(points_lat2)) ' points']);
else
    disp(['  Points generated: ' num2str(length(points_lat2))]);
end

% Generate hyperbola 3 (RX2-RX3) with reliability check
disp(' ');
disp('--- Hyperbola 3: RX2 & RX3 ---');
% IMPROVEMENT: Tetap generate hiperbola untuk visualisasi, tapi beri warning jika tidak reliable
if ~reliable23
    disp(['<strong>WARNING: Hyperbola 3 has LOW reliability (' num2str(reliability23, '%.6f') ') below threshold (' num2str(RELIABILITY_THRESHOLD) ')</strong>']);
    disp('Hyperbola will be generated for visualization but given very low weight in intersection calculation.');
end
% First try with standard gen_hyperbola
disp('Using gen_hyperbola (standard)...');
[points_lat3, points_long3] = gen_hyperbola(doa_meters23, rx2_lat, rx2_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long, 'RX2', 'RX3');
% Check if points are insufficient, retry with improved version
if length(points_lat3) <= MIN_POINTS_FOR_RETRY && has_improved_func
    disp(['  Points generated: ' num2str(length(points_lat3)) ' <= ' num2str(MIN_POINTS_FOR_RETRY) ', retrying with gen_hyperbola_improved...']);
    [points_lat3, points_long3] = gen_hyperbola_improved(doa_meters23, rx2_lat, rx2_long, rx3_lat, rx3_long, geo_ref_lat, geo_ref_long, 'RX2', 'RX3');
    disp(['  Improved version generated: ' num2str(length(points_lat3)) ' points']);
else
    disp(['  Points generated: ' num2str(length(points_lat3))]);
end

% figure;
% hold on;
% plot(points_long1, points_lat1, 'r.', 'MarkerSize', 10);
% plot(points_long2, points_lat2, 'g.', 'MarkerSize', 10);
% plot(points_long3, points_lat3, 'b.', 'MarkerSize', 10);
% plot(rx1_long, rx1_lat, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
% plot(rx2_long, rx2_lat, 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
% plot(rx3_long, rx3_lat, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
% grid on;
% legend('RX1 - RX2', 'RX1 - RX3', 'RX2 - RX3', 'RX1', 'RX2', 'RX3');
% axis equal;
% xlabel('Longitude');
% ylabel('Latitude');
% title(['Hiperbola Plot RX1, RX2, RX3']);
% return;

%% Generate minimum distance
disp(' ');
disp('______________________________________________________________________________________________');
disp('GENERATE MINIMUM DISTANCE (WEIGHTED)');

% === ORIGINAL CODE (COMMENTED) ===
disp(['poin lat1 = ', num2str(length(points_lat1))]);
disp(['poin lat2 = ', num2str(length(points_lat2))]);
disp(['poin lat3 = ', num2str(length(points_lat3))]);
% Penentuan titik tengah dari perpotongan garis hiperbola RX1 & RX2
for i = 1:length(points_lat1)
    for j = 1:length(points_lat2)
        dist12(i,j) = dist_latlong(points_lat1(i), points_long1(i), points_lat2(j), points_long2(j), geo_ref_lat, geo_ref_long);
    end
end

[min_dist12, min_idx12] = min(dist12(:));
[row_idx12, col_idx12] = ind2sub(size(dist12), min_idx12);
avg_point_lat12 = (points_lat1(row_idx12) + points_lat2(col_idx12)) / 2;
avg_point_long12 = (points_long1(row_idx12) + points_long2(col_idx12)) / 2;
% disp(['avg point lat12', num2str(avg_point_lat12)]);
% disp(['avg point long12', num2str(avg_point_long12)]);

for i = 1:length(points_lat1)
    for j = 1:length(points_lat3)
        dist13(i,j) = dist_latlong(points_lat1(i), points_long1(i), points_lat3(j), points_long3(j), geo_ref_lat, geo_ref_long);
    end
end

[min_dist13, min_idx13] = min(dist13(:));
[row_idx13, col_idx13] = ind2sub(size(dist13), min_idx13);
avg_point_lat13 = (points_lat1(row_idx13) + points_lat3(col_idx13)) / 2;
avg_point_long13 = (points_long1(row_idx13) + points_long3(col_idx13)) / 2;

for i = 1:length(points_lat2)
    for j = 1:length(points_lat3)
        dist23(i,j) = dist_latlong(points_lat2(i), points_long2(i), points_lat3(j), points_long3(j), geo_ref_lat, geo_ref_long);
    end
end

[min_dist23, min_idx23] = min(dist23(:));
[row_idx23, col_idx23] = ind2sub(size(dist23), min_idx23);
avg_point_lat23 = (points_lat2(row_idx23) + points_lat3(col_idx23)) / 2;
avg_point_long23 = (points_long2(row_idx23) + points_long3(col_idx23)) / 2;
% disp(['avg point lat23', num2str(avg_point_lat23)]);
% disp(['avg point long23', num2str(avg_point_long23)]);

avg_point_lat123 = (avg_point_lat12 + avg_point_lat13 + avg_point_lat23) / 3;
avg_point_long123 = (avg_point_long12 + avg_point_long13 + avg_point_long23) / 3;

% === IMPROVED CODE WITH WEIGHTED INTERSECTION ===
% num_hyp1 = length(points_lat1);
% num_hyp2 = length(points_lat2);
% num_hyp3 = length(points_lat3);

% disp(['poin lat1 = ', num2str(num_hyp1), ', weight = ', num2str(weight12, '%.3f')]);
% disp(['poin lat2 = ', num2str(num_hyp2), ', weight = ', num2str(weight13, '%.3f')]);
% disp(['poin lat3 = ', num2str(num_hyp3), ', weight = ', num2str(weight23, '%.3f')]);

% % Initialize intersection points
% valid_intersections = 0;
% intersection_lats = [];
% intersection_longs = [];
% intersection_weights = [];

% % Calculate intersection 1-2 (if both valid)
% if num_hyp1 > 0 && num_hyp2 > 0
%     disp('Calculating intersection between Hyperbola 1 and 2...');
%     for i = 1:num_hyp1
%         for j = 1:num_hyp2
%             dist12(i,j) = dist_latlong(points_lat1(i), points_long1(i), points_lat2(j), points_long2(j), geo_ref_lat, geo_ref_long);
%         end
%     end

%     [min_dist12, min_idx12] = min(dist12(:));
%     [row_idx12, col_idx12] = ind2sub(size(dist12), min_idx12);
%     avg_point_lat12 = (points_lat1(row_idx12) + points_lat2(col_idx12)) / 2;
%     avg_point_long12 = (points_long1(row_idx12) + points_long2(col_idx12)) / 2;

%     valid_intersections = valid_intersections + 1;
%     intersection_lats(valid_intersections) = avg_point_lat12;
%     intersection_longs(valid_intersections) = avg_point_long12;
%     intersection_weights(valid_intersections) = (weight12 + weight13) / 2; % Average of two weights involved

%     disp(['  Intersection 1-2 found at: (' num2str(avg_point_lat12, '%.6f') ', ' num2str(avg_point_long12, '%.6f') ')']);
%     disp(['  Minimum distance: ' num2str(min_dist12*1000, '%.2f') ' meters']);
% else
%     disp('Skipping intersection 1-2: insufficient points');
%     avg_point_lat12 = NaN;
%     avg_point_long12 = NaN;
% end

% % Calculate intersection 1-3 (if both valid)
% if num_hyp1 > 0 && num_hyp3 > 0
%     disp('Calculating intersection between Hyperbola 1 and 3...');
%     for i = 1:num_hyp1
%         for j = 1:num_hyp3
%             dist13(i,j) = dist_latlong(points_lat1(i), points_long1(i), points_lat3(j), points_long3(j), geo_ref_lat, geo_ref_long);
%         end
%     end

%     [min_dist13, min_idx13] = min(dist13(:));
%     [row_idx13, col_idx13] = ind2sub(size(dist13), min_idx13);
%     avg_point_lat13 = (points_lat1(row_idx13) + points_lat3(col_idx13)) / 2;
%     avg_point_long13 = (points_long1(row_idx13) + points_long3(col_idx13)) / 2;

%     valid_intersections = valid_intersections + 1;
%     intersection_lats(valid_intersections) = avg_point_lat13;
%     intersection_longs(valid_intersections) = avg_point_long13;
%     intersection_weights(valid_intersections) = (weight12 + weight23) / 2;

%     disp(['  Intersection 1-3 found at: (' num2str(avg_point_lat13, '%.6f') ', ' num2str(avg_point_long13, '%.6f') ')']);
%     disp(['  Minimum distance: ' num2str(min_dist13*1000, '%.2f') ' meters']);
% else
%     disp('Skipping intersection 1-3: insufficient points');
%     avg_point_lat13 = NaN;
%     avg_point_long13 = NaN;
% end

% % Calculate intersection 2-3 (if both valid)
% if num_hyp2 > 0 && num_hyp3 > 0
%     disp('Calculating intersection between Hyperbola 2 and 3...');
%     for i = 1:num_hyp2
%         for j = 1:num_hyp3
%             dist23(i,j) = dist_latlong(points_lat2(i), points_long2(i), points_lat3(j), points_long3(j), geo_ref_lat, geo_ref_long);
%         end
%     end

%     [min_dist23, min_idx23] = min(dist23(:));
%     [row_idx23, col_idx23] = ind2sub(size(dist23), min_idx23);
%     avg_point_lat23 = (points_lat2(row_idx23) + points_lat3(col_idx23)) / 2;
%     avg_point_long23 = (points_long2(row_idx23) + points_long3(col_idx23)) / 2;

%     valid_intersections = valid_intersections + 1;
%     intersection_lats(valid_intersections) = avg_point_lat23;
%     intersection_longs(valid_intersections) = avg_point_long23;
%     intersection_weights(valid_intersections) = (weight13 + weight23) / 2;

%     disp(['  Intersection 2-3 found at: (' num2str(avg_point_lat23, '%.6f') ', ' num2str(avg_point_long23, '%.6f') ')']);
%     disp(['  Minimum distance: ' num2str(min_dist23*1000, '%.2f') ' meters']);
% else
%     disp('Skipping intersection 2-3: insufficient points');
%     avg_point_lat23 = NaN;
%     avg_point_long23 = NaN;
% end

% % Calculate final weighted average position
% if valid_intersections > 0
%     % Normalize weights
%     intersection_weights = intersection_weights / sum(intersection_weights);

%     % Weighted average
%     avg_point_lat123 = sum(intersection_lats .* intersection_weights);
%     avg_point_long123 = sum(intersection_longs .* intersection_weights);

%     disp(' ');
%     disp(['FINAL WEIGHTED POSITION (based on ' num2str(valid_intersections) ' valid intersections):']);
%     disp(['  Latitude:  ' num2str(avg_point_lat123, '%.6f')]);
%     disp(['  Longitude: ' num2str(avg_point_long123, '%.6f')]);

%     % Also calculate unweighted average for comparison
%     avg_point_lat123_unweighted = mean(intersection_lats);
%     avg_point_long123_unweighted = mean(intersection_longs);

%     disp(' ');
%     disp('COMPARISON:');
%     disp(['  Unweighted average: (' num2str(avg_point_lat123_unweighted, '%.6f') ', ' num2str(avg_point_long123_unweighted, '%.6f') ')']);
%     disp(['  Weighted average:   (' num2str(avg_point_lat123, '%.6f') ', ' num2str(avg_point_long123, '%.6f') ')']);

%     % Calculate difference
%     diff_meters = dist_latlong(avg_point_lat123, avg_point_long123, avg_point_lat123_unweighted, avg_point_long123_unweighted, geo_ref_lat, geo_ref_long) * 1000;
%     disp(['  Difference between weighted and unweighted: ' num2str(diff_meters, '%.2f') ' meters']);
% else
%     disp('<strong>ERROR: No valid hyperbola intersections found!</strong>');
%     avg_point_lat123 = geo_ref_lat;
%     avg_point_long123 = geo_ref_long;
% end

% % Fallback: Jika ada NaN, gunakan nilai yang ada
% if isnan(avg_point_lat12)
%     avg_point_lat12 = avg_point_lat123;
%     avg_point_long12 = avg_point_long123;
% end
% if isnan(avg_point_lat13)
%     avg_point_lat13 = avg_point_lat123;
%     avg_point_long13 = avg_point_long123;
% end
% if isnan(avg_point_lat23)
%     avg_point_lat23 = avg_point_lat123;
%     avg_point_long23 = avg_point_long123;
% end

% figure;
% hold on;
% plot(points_lat1(row_idx12), points_long1(row_idx12), 'r.', 'MarkerSize', 15);
% plot(points_lat2(col_idx12), points_long2(col_idx12), 'r.', 'MarkerSize', 15);
% plot(avg_point_lat12, avg_point_long12, 'r.', 'MarkerSize', 30);

% plot(points_lat1(row_idx13), points_long1(row_idx13), 'g.', 'MarkerSize', 15);
% plot(points_lat3(col_idx13), points_long3(col_idx13), 'g.', 'MarkerSize', 15);
% plot(avg_point_lat13, avg_point_long13, 'g.', 'MarkerSize', 30);

% plot(points_lat2(row_idx23), points_long2(row_idx23), 'b.', 'MarkerSize', 15);
% plot(points_lat3(col_idx23), points_long3(col_idx23), 'b.', 'MarkerSize', 15);
% plot(avg_point_lat23, avg_point_long23, 'b.', 'MarkerSize', 30);
% plot(avg_point_lat123, avg_point_long123, 'k.', 'MarkerSize', 50);
% grid on;
% legend('point hiperbola1', 'point hiperbola2', 'avg hiperbola12', 'point hiperbola1', 'point hiperbola3', 'avg hiperbola13', 'point hiperbola2', 'point hiperbola3', 'avg hiperbola23', 'avg point all');
% axis equal;
% xlabel('Longitude');
% ylabel('Latitude');
% title(['Average Hiperbola Plot RX1, RX2, RX3']);
% return;


disp(' ');
disp('______________________________________________________________________________________________');
disp('GENERATE HTML');

% Display hyperbola reliability summary
% disp(' ');
% disp('HYPERBOLA RELIABILITY SUMMARY:');
% if reliable12
%     disp(['  Hyperbola 1 (RX1-RX2): ' num2str(length(points_lat1)) ' points, reliability = ' num2str(reliability12, '%.6f') ' (' num2str(reliability12*100, '%.2f') '%) ✓ RELIABLE']);
% else
%     disp(['  Hyperbola 1 (RX1-RX2): ' num2str(length(points_lat1)) ' points, reliability = ' num2str(reliability12, '%.6f') ' (' num2str(reliability12*100, '%.2f') '%) ✗ LOW']);
% end
% if reliable13
%     disp(['  Hyperbola 2 (RX1-RX3): ' num2str(length(points_lat2)) ' points, reliability = ' num2str(reliability13, '%.6f') ' (' num2str(reliability13*100, '%.2f') '%) ✓ RELIABLE']);
% else
%     disp(['  Hyperbola 2 (RX1-RX3): ' num2str(length(points_lat2)) ' points, reliability = ' num2str(reliability13, '%.6f') ' (' num2str(reliability13*100, '%.2f') '%) ✗ LOW']);
% end
% if reliable23
%     disp(['  Hyperbola 3 (RX2-RX3): ' num2str(length(points_lat3)) ' points, reliability = ' num2str(reliability23, '%.6f') ' (' num2str(reliability23*100, '%.2f') '%) ✓ RELIABLE']);
% else
%     disp(['  Hyperbola 3 (RX2-RX3): ' num2str(length(points_lat3)) ' points, reliability = ' num2str(reliability23, '%.6f') ' (' num2str(reliability23*100, '%.2f') '%) ✗ LOW - Low weight in calculation']);
% end
% disp(' ');

rx_lat_positions  = [rx1_lat   rx2_lat   rx3_lat   tx_cari_lat   tx_ref_lat  geo_ref_lat   avg_point_lat123   center_point_lat    avg_point_lat12   avg_point_lat13   avg_point_lat23];
rx_long_positions = [rx1_long  rx2_long  rx3_long  tx_cari_long  tx_ref_long  geo_ref_long  avg_point_long123  center_point_long  avg_point_long12  avg_point_long13  avg_point_long23];

hyperbola_lat_cell  = {points_lat1,  points_lat2, points_lat3};
hyperbola_long_cell = {points_long1, points_long2, points_long3};

% Generate heatmap with improved or original method
if use_improved_heatmap
    disp(' ');
    disp('Using IMPROVED heatmap generation with adaptive weighting...');
    [heatmap_long, heatmap_lat, heatmap_mag, start_lat, stop_lat, start_long, stop_long] = ...
        create_heatmap_improved(doa_meters12, doa_meters13, doa_meters23, ...
        rx1_lat, rx1_long, rx2_lat, rx2_long, rx3_lat, rx3_long, ...
        heatmap_resolution, geo_ref_lat, geo_ref_long, ...
        reliability12, reliability13, reliability23);
else
    disp(' ');
    disp('Using ORIGINAL heatmap generation...');
    [heatmap_long, heatmap_lat, heatmap_mag, start_lat, stop_lat, start_long, stop_long] = ...
        create_heatmap(doa_meters12, doa_meters13, doa_meters23, ...
        rx1_lat, rx1_long, rx2_lat, rx2_long, rx3_lat, rx3_long, ...
        heatmap_resolution, geo_ref_lat, geo_ref_long);
end

heatmap_cell = {heatmap_long, heatmap_lat, heatmap_mag, start_lat, stop_lat, start_long, stop_long};
delay_ref_sample = {delay_ref_sample12, delay_ref_sample13, delay_ref_sample23};

%% ======================================================================
%% CALCULATE DISTANCE ERRORS FOR HYPERBOLA AND HEATMAP ESTIMATIONS
%% ======================================================================

% Calculate distance error for hyperbola (distance from estimated position to target)
dist_error_hyperbola = haversine_distance(tx_cari_lat, tx_cari_long, avg_point_lat123, avg_point_long123);

% Calculate statistics
mae_hyperbola = dist_error_hyperbola;
std_hyperbola = 0;

% Calculate distance error for heatmap (distance from peak heatmap position to target)
[~, idx_peak] = max(heatmap_mag(:));
[idx_peak_long, idx_peak_lat] = ind2sub(size(heatmap_mag), idx_peak);

if idx_peak_long <= length(heatmap_long) && idx_peak_lat <= length(heatmap_lat)
    peak_lat = heatmap_lat(idx_peak_lat);
    peak_long = heatmap_long(idx_peak_long);
    dist_error_heatmap = haversine_distance(tx_cari_lat, tx_cari_long, peak_lat, peak_long); % in meters
else
    dist_error_heatmap = NaN;
end

% Store MAE values for HTML file
mae_data = struct('hyperbola_mae', mae_hyperbola, 'hyperbola_std', std_hyperbola, ...
    'heatmap_mae', dist_error_heatmap, 'heatmap_std', 0);

% Generate output filename with appropriate suffix
if use_improved_heatmap
    heatmap_suffix = '_improved';
else
    heatmap_suffix = '';
end

if strcmp(map_mode, 'google_maps')
    % for google maps
    output_filename = ['result/map_' file_identifier '_' corr_type '_interp' num2str(interpol_factor) '_bw' int2str(signal_bandwidth_khz) '_smooth' int2str(smoothing_factor) heatmap_suffix '_gm.html'];
    create_html_file_gm(output_filename, rx_lat_positions, rx_long_positions, hyperbola_lat_cell, hyperbola_long_cell, heatmap_cell, heatmap_threshold, mae_data);
else
    % for open street map
    output_filename = [folder_result 'newmap_' file_identifier '_' corr_type '_interp' num2str(interpol_factor) '_bw' int2str(signal_bandwidth_khz) '_smooth' int2str(smoothing_factor) heatmap_suffix '_osm.html'];
    create_html_file_osm(output_filename, rx_lat_positions, rx_long_positions, hyperbola_lat_cell, hyperbola_long_cell, heatmap_cell, heatmap_threshold, delay_ref_sample, mae_data);
end
disp('______________________________________________________________________________________________');

%% Local helper: Haversine distance in meters
    function d = haversine_distance(lat1, lon1, lat2, lon2)
        R = 6371.0; % Earth radius in kilometers
        dlat = deg2rad(lat2 - lat1);
        dlon = deg2rad(lon2 - lon1);
        a = sin(dlat/2).^2 + cos(deg2rad(lat1)) .* cos(deg2rad(lat2)) .* sin(dlon/2).^2;
        c = 2 * atan2(sqrt(a), sqrt(1 - a));
        d = R * c * 1000; % convert to meters
    end

end % End of function evaluation_main
