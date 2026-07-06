function snr_results = calculate_snr(varargin)
% =========================================================================
%  SNR (Signal-to-Noise Ratio) Measurement Script
%  Untuk mengukur SNR pada data RTL-SDR IQ
% =========================================================================
%
% Usage:
%   snr_results = calculate_snr()                    % measure all files in data_121
%   snr_results = calculate_snr('filename.dat')     % measure single file
%   snr_results = calculate_snr('--dir', 'folder')  % measure all files in folder
%
% Output:
%   snr_results: struct dengan field SNR, SNR_dB, power_signal, power_noise
%

% Parse input arguments
if nargin == 0
    % Default: process all files in data_121
    input_dir = './data_121/';
    file_pattern = '*.dat';
    single_file = '';
elseif nargin == 1
    % Single file specified
    single_file = varargin{1};
    input_dir = '';
    file_pattern = '';
elseif nargin == 2 && strcmp(varargin{1}, '--dir')
    % Directory specified
    input_dir = varargin{2};
    file_pattern = '*.dat';
    single_file = '';
else
    error('Usage: calculate_snr() or calculate_snr(filename) or calculate_snr(--dir, folder)');
end

% Add functions to PATH
[p,~,~] = fileparts(mfilename('fullpath'));
addpath([p '/functions']);

fprintf('\n');
fprintf('=========================================================================\n');
fprintf('SNR MEASUREMENT FOR RTL-SDR IQ DATA\n');
fprintf('=========================================================================\n\n');

% Get list of files to process
if ~isempty(single_file)
    % Try to find the single file with various path permutations
    if isfile(single_file)
        files = dir(single_file);
    elseif isfile(['data_121/' single_file])
        files = dir(['data_121/' single_file]);
    elseif isfile(['./data_121/' single_file])
        files = dir(['./data_121/' single_file]);
    else
        % Try wildcard if it contains one
        if contains(single_file, '*')
            files = dir(single_file);
            if isempty(files)
                files = dir(['data_121/' single_file]);
            end
        else
            error('No files found matching: %s', single_file);
        end
    end
else
    files = dir([input_dir file_pattern]);
end

if isempty(files)
    error('No files found');
end

% Initialize results array
snr_results = [];

% Process each file
for file_idx = 1:length(files)
    if files(file_idx).isdir
        continue;
    end
    
    filename = files(file_idx).name;
    filepath = fullfile(input_dir, filename);
    if isempty(input_dir) && ~isempty(single_file)
        filepath = filename;
    end
    
    fprintf('Processing: %s\n', filepath);
    
    try
        % Read IQ data
        [signal, file_size_info] = read_file_iq(filepath);
        
        % Check signal validity first
        has_nan = any(isnan(signal(:)));
        has_inf = any(isinf(signal(:)));
        
        if has_nan || has_inf
            fprintf('  WARNING: Signal contains NaN or Inf values - file might be corrupted\n');
        end
        
        % Remove NaN and Inf for analysis
        valid_idx = isfinite(signal);
        signal_valid = signal(valid_idx);
        
        if length(signal_valid) < 1000
            fprintf('  ERROR: Not enough valid samples (only %d valid out of %d)\n', ...
                length(signal_valid), length(signal));
            error('File appears to be corrupted or lacks sufficient valid data');
        end
        
        % Make sure we don't have extreme values
        signal_mag = abs(signal_valid);
        if max(signal_mag) > 100 || min(signal_mag(signal_mag > 0)) < 1e-10
            fprintf('  WARNING: Signal has extreme range (%.2e to %.2e)\n', ...
                min(signal_mag(signal_mag > 0)), max(signal_mag));
            % Normalize signal for analysis
            signal_median = median(signal_mag);
            if signal_median > 0
                signal_valid = signal_valid / signal_median;
            end
        end
        
        % Determine which signal segment to use based on file size
        num_samples_per_freq = 1.2e6;
        num_guard = 2^12;  % Guard interval
        
        % ===== Segment Selection Strategy =====
        if file_size_info.num_samples < num_samples_per_freq
            % File too small - use entire signal for analysis
            fprintf('  WARNING: File too small (%.2f MB). Using entire signal.\n', file_size_info.file_size_mb);
            signal_to_analyze = signal_valid;
            is_short_file = true;
        elseif file_size_info.num_samples < 2*num_samples_per_freq
            % Only reference segment available
            fprintf('  INFO: Incomplete file - only reference segment available (%.2f MB).\n', file_size_info.file_size_mb);
            signal_to_analyze = signal_valid;
            is_short_file = true;
        else
            % Full file or at least reference + measurement available
            % Use measurement signal (more interesting for SNR analysis)
            start_idx = num_samples_per_freq + num_guard + 1;
            end_idx = min(start_idx + num_samples_per_freq - 1, length(signal_valid));
            signal_to_analyze = signal_valid(start_idx : end_idx);
            is_short_file = false;
        end
        
        % ===== SIMPLIFIED SNR MEASUREMENT (Practical Approach) =====
        
        % Limit to reasonable analysis size
        test_samples = min(100000, length(signal_to_analyze));
        test_signal = signal_to_analyze(1:test_samples);
        
        % METHOD 1: RMS-based SNR
        signal_rms = rms(test_signal);
        signal_power = signal_rms^2;
        
        % Estimate noise from weakest 10% of magnitudes
        signal_mag = abs(test_signal);
        signal_mag_sorted = sort(signal_mag);
        noise_est_idx = floor(0.1 * length(signal_mag_sorted));
        noise_rms_1 = mean(signal_mag_sorted(1:max(1, noise_est_idx)));
        
        if noise_rms_1 > 0 && isfinite(signal_power)
            snr_linear = signal_power / (noise_rms_1^2);
            snr_db = 10 * log10(max(snr_linear, 0.01));
        else
            snr_linear = 0;
            snr_db = -20;
        end
        
        % Clamp to reasonable range
        snr_db = max(snr_db, -20);
        snr_db = min(snr_db, 50);
        
        % METHOD 2: Peak-to-Average Ratio
        peak_amp = max(signal_mag);
        avg_amp = mean(signal_mag);
        
        if avg_amp > 0
            snr_linear2 = (peak_amp / avg_amp)^2;
            snr_db2 = 10 * log10(max(snr_linear2, 0.01));
        else
            snr_linear2 = 0;
            snr_db2 = -20;
        end
        
        snr_db2 = max(snr_db2, -20);
        snr_db2 = min(snr_db2, 50);
        
        % METHOD 3: Simple FFT-based approach
        fft_len = min(2^14, test_samples);
        spec = abs(fft(test_signal(1:fft_len))).^2 / fft_len;
        
        [peak_val, peak_idx] = max(spec);
        spec_median = median(spec);
        
        if spec_median > 0
            snr_linear3 = peak_val / spec_median;
            snr_db3 = 10 * log10(max(snr_linear3, 0.01));
        else
            snr_linear3 = 0;
            snr_db3 = -20;
        end
        
        snr_db3 = max(snr_db3, -20);
        snr_db3 = min(snr_db3, 50);
        
        % Store results
        result = struct();
        result.filename = filename;
        result.file_size_mb = file_size_info.file_size_mb;
        result.num_samples = file_size_info.num_samples;
        result.is_short_file = is_short_file;
        result.method1_snr_linear = snr_linear;
        result.method1_snr_db = snr_db;
        result.method2_snr_linear = snr_linear2;
        result.method2_snr_db = snr_db2;
        result.method3_snr_linear = snr_linear3;
        result.method3_snr_db = snr_db3;
        result.avg_snr_db = mean([snr_db, snr_db2, snr_db3]);
        result.rms_signal = signal_rms;
        result.rms_noise = noise_rms_1;
        
        snr_results = [snr_results; result];
        
        % Display results
        fprintf('  Method 1 (Power-based):     %.2f dB (linear: %.2f)\n', snr_db, snr_linear);
        fprintf('  Method 2 (Peak-to-noise):   %.2f dB (linear: %.2f)\n', snr_db2, snr_linear2);
        fprintf('  Method 3 (Spectral):         %.2f dB (linear: %.2f)\n', snr_db3, snr_linear3);
        avg_snr = mean([snr_db, snr_db2, snr_db3]);
        fprintf('  Average SNR:                 %.2f dB\n', avg_snr);
        if is_short_file
            fprintf('  Status:                      ⚠ SHORT FILE (%.2f MB)\n', file_size_info.file_size_mb);
        end
        fprintf('\n');
        
    catch ME
        fprintf('  ERROR: %s\n\n', ME.message);
    end
end

% Display summary
fprintf('=========================================================================\n');
fprintf('SUMMARY\n');
fprintf('=========================================================================\n');
fprintf('Total files processed: %d\n', length(snr_results));

if ~isempty(snr_results)
    fprintf('\nAverage SNR (across all files, Method 1): %.2f dB\n', ...
        mean([snr_results.method1_snr_db]));
    fprintf('Average SNR (across all files, Method 2): %.2f dB\n', ...
        mean([snr_results.method2_snr_db]));
    fprintf('Average SNR (across all files, Method 3): %.2f dB\n', ...
        mean([snr_results.method3_snr_db]));
    fprintf('\nRange of SNR (Method 1): %.2f - %.2f dB\n', ...
        min([snr_results.method1_snr_db]), max([snr_results.method1_snr_db]));
end

fprintf('\n');

end

function [signal, file_info] = read_file_iq(filename)
% Read RTL-SDR IQ data from .dat file
%
% Format: 4-byte float (IQIQIQ...)
% Returns: signal (complex), file_info (struct with size details)

% Handle path issues
if ~isfile(filename)
    % Try to find the file in current directory
    [~, name, ext] = fileparts(filename);
    if isfile([name ext])
        filename = [name ext];
    elseif isfile(['data_121/' name ext])
        filename = ['data_121/' name ext];
    elseif isfile(['./data_121/' name ext])
        filename = ['./data_121/' name ext];
    else
        error('Cannot find file: %s', filename);
    end
end

fid = fopen(filename, 'rb');
if fid == -1
    error('Cannot open file: %s', filename);
end

% Get file size
fseek(fid, 0, 'eof');
file_size_bytes = ftell(fid);
fseek(fid, 0, 'bof');

% Read all data as float32
data = fread(fid, 'float');
fclose(fid);

% Calculate number of samples
num_float_samples = length(data);
num_complex_samples = num_float_samples / 2;

% Reshape to I and Q pairs and create complex signal
if mod(length(data), 2) == 0
    signal = complex(data(1:2:end), data(2:2:end));
else
    % Handle odd number of samples
    signal = complex(data(1:2:end-1), data(2:2:end));
end

% Return file information
file_info = struct();
file_info.file_size_bytes = file_size_bytes;
file_info.file_size_mb = file_size_bytes / (1024*1024);
file_info.num_float_samples = num_float_samples;
file_info.num_samples = length(signal);  % Complex samples

end
