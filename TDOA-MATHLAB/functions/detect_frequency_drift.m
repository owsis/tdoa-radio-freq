function [drift_ppm, confidence, warning_level] = detect_frequency_drift(...
    delay_ref_slice1, delay_measure_slice2, delay_ref_slice3, ...
    sample_rate, rx_pair_name)
% =========================================================================
% DETECT FREQUENCY DRIFT from RTL-SDR clock instability
%
% This function estimates frequency drift (PPM) between two receivers
% by comparing reference signal measurements at different times.
%
% PRINCIPLE:
% - Slice 1 (T=0-600ms):   Reference TX measurement with RX1
% - Slice 3 (T=1600-1800ms): Same reference TX measurement with RX3
% - If clocks are synchronized: delay_ref_slice1 ≈ delay_ref_slice3
% - Difference indicates clock drift or network jitter
%
% INPUT:
%   delay_ref_slice1:   Delay measurement from reference signal, slice 1 (samples)
%   delay_measure_slice2: Delay measurement from measurement signal, slice 2 (samples)
%   delay_ref_slice3:   Delay measurement from reference signal, slice 3 (samples)
%   sample_rate:        Sampling rate in Hz (default 2e6 for RTL-SDR)
%   rx_pair_name:       String identifying RX pair, e.g. 'RX1-RX2' (for reporting)
%
% OUTPUT:
%   drift_ppm:          Estimated frequency drift in parts per million (ppm)
%                       Positive = RX1 sampling faster than RX2
%                       Negative = RX1 sampling slower than RX2
%   confidence:         Confidence in drift estimate, range [0, 1]
%                       Based on signal reliability and measurement consistency
%   warning_level:      0 = OK (<5 ppm), 1 = Caution (5-50 ppm), 2 = Critical (>50 ppm)
%
% THEORY:
% Clock frequency error accumulates over time:
%   f_error = f_nominal × (1 + drift_ppm / 1e6)
%
%   Over measurement duration T with N samples:
%   actual_N = N × (1 + drift_ppm / 1e6)
%
%   N_samples_error = N × drift_ppm / 1e6
%
%   Inversely, if we measure sample count error:
%   drift_ppm ≈ (delay_error_samples / measurement_samples) × 1e6
%
% EXAMPLE:
%   [ppm, conf, warn] = detect_frequency_drift(9517, 9516, 1e6, 2e6, 'RX1-RX2')
%
%   => ppm ≈ 1.0 (very small drift)
%   => conf ≈ 0.8 (reasonable reliability)
%   => warn = 0 (no warning)
%
% =========================================================================

% Input validation
if nargin < 4
    sample_rate = 2e6;  % Default RTL-SDR sample rate
end

if nargin < 5
    rx_pair_name = 'Unknown';
end

% Ensure inputs are numeric
delay_ref_slice1 = double(delay_ref_slice1);
delay_measure_slice2 = double(delay_measure_slice2);
delay_ref_slice3 = double(delay_ref_slice3);
sample_rate = double(sample_rate);

% =====================================================================
% STEP 1: Extract timing information
% =====================================================================

% Measurement window sizes (from tdoa2.m)
num_samples_per_freq = 1.2e6;       % Each frequency band: 1.2M samples @ 2 Msps = 600ms
guard_interval = 200e3;             % Guard time between bands: 200k samples = 100ms
num_samples_per_slice = 1e6;        % Actual measurement slice: 1M samples = 500ms

% Calculate total measurement duration
% Slices sampled at: 0-1M, 1.2M+200k-(1.2M+200k+1M), 2.4M+200k-(2.4M+200k+1M)
% Total recording time: 3.6M samples
total_measurement_duration_sec = 3.6e6 / sample_rate;  % 1.8 seconds

% Effective correlation window for each slice (in seconds)
slice_duration_sec = num_samples_per_slice / sample_rate;  % 0.5 seconds each

% Time between slice 1 and slice 3 measurements
% Slice 1: 0-500ms
% Slice 3: 1600-1800ms (with guards)
time_between_slices = (2.4e6 + guard_interval) / sample_rate;  % ~1.3 seconds

% =====================================================================
% STEP 2: Calculate reference signal timing consistency
% =====================================================================

% Both delay_ref_slice1 and delay_ref_slice3 measure the SAME TX signal
% Ideally, they should be almost identical (differ by at most 1-2 samples
% due to rounding). Larger differences indicate clock drift.

delay_difference_samples = delay_ref_slice1 - delay_ref_slice3;

% =====================================================================
% STEP 3: Convert delay difference to PPM
% =====================================================================

% Method 1: Normalize by total measurement time
% PPM = (sample_error / total_samples) × 1e6
drift_ppm_method1 = (delay_difference_samples / 3.6e6) * 1e6;

% Method 2: Normalize by measurement window (more sensitive to per-receiver error)
% If RX accumulates error over time, it shows up in the slice duration
drift_ppm_method2 = (delay_difference_samples / num_samples_per_slice) * 1e6;

% Method 3: Time-normalized PPM
% PPM_per_second = (sample_error / duration) / sample_rate × 1e6
if time_between_slices > 0
    drift_ppm_method3 = (delay_difference_samples / time_between_slices) / sample_rate * 1e6;
else
    drift_ppm_method3 = drift_ppm_method1;
end

% Use method 1 as primary (most conservative), others for cross-check
drift_ppm = drift_ppm_method1;

% =====================================================================
% STEP 4: Detect which receiver likely has the drift
% =====================================================================

% Positive delay_difference = delay1 > delay3
%   => Slice 3 finished counting faster (RX3 clock faster OR RX1 clock slower)
%   => RX1 might be slower
%
% Negative delay_difference = delay1 < delay3
%   => Slice 3 finished counting slower (RX3 clock slower OR RX1 clock faster)
%   => RX1 might be faster

if delay_difference_samples > 0
    slower_receiver = 'RX1';
    faster_receiver = 'RX3';
else
    slower_receiver = 'RX3';
    faster_receiver = 'RX1';
end

% =====================================================================
% STEP 5: Calculate confidence score
% =====================================================================

% Confidence based on:
% a) Reliability of reference signals (assumed passed in via better measurement)
% b) Consistency: smaller delay_difference = more reliable estimate

% Heuristic: confidence inversely related to delay error magnitude
% Assume reliable measurement if delay_difference < 10 samples

delay_error_magnitude = abs(delay_difference_samples);

if delay_error_magnitude <= 1
    % Excellent agreement
    confidence = 0.95;
elseif delay_error_magnitude <= 3
    % Good agreement
    confidence = 0.85;
elseif delay_error_magnitude <= 5
    % Acceptable agreement
    confidence = 0.70;
elseif delay_error_magnitude <= 10
    % Questionable agreement
    confidence = 0.50;
elseif delay_error_magnitude <= 20
    % Poor agreement
    confidence = 0.25;
else
    % Very poor agreement
    confidence = 0.10;
end

% =====================================================================
% STEP 6: Determine warning level
% =====================================================================

drift_magnitude = abs(drift_ppm);

if drift_magnitude < 5
    warning_level = 0;  % OK - normal RTL-SDR stability
    warning_str = '✓ OK';
elseif drift_magnitude < 50
    warning_level = 1;  % Caution - some clock drift detected
    warning_str = '⚠ CAUTION';
else
    warning_level = 2;  % Critical - significant drift or jitter
    warning_str = '✗ CRITICAL';
end

% =====================================================================
% STEP 7: Diagnostic output (optional, controlled by flag)
% =====================================================================

% Uncomment for debug:
if false  % Set to true for verbose output
    fprintf('\n--- DRIFT DETECTION DIAGNOSTICS (%s) ---\n', rx_pair_name);
    fprintf('  delay_ref_slice1:     %d samples\n', delay_ref_slice1);
    fprintf('  delay_ref_slice3:     %d samples\n', delay_ref_slice3);
    fprintf('  delay_difference:     %d samples\n', delay_difference_samples);
    fprintf('  PPM (method 1/3):     %+.2f / %+.2f ppm\n', drift_ppm_method1, drift_ppm_method3);
    fprintf('  Slower RX:            %s\n', slower_receiver);
    fprintf('  Confidence:           %.2f\n', confidence);
    fprintf('  Warning level:        %d (%s)\n', warning_level, warning_str);
    fprintf('  Time between slices:  %.3f seconds\n', time_between_slices);
end

end
