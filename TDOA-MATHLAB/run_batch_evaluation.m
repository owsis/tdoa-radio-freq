% filepath: run_batch_evaluation.m
% Script untuk menjalankan evaluation_main 30 kali dengan file berbeda
% Captures ALL console output to timestamped text file with metrics extraction
% Pattern: "933_1031_2025_6_12_HH_MM.dat" (HH:MM from 11:12 to 11:41)

clc;
clear;

% ========== OUTPUT FILE SETUP (MUST BE BEFORE HOUR VARIABLE) ==========
% Generate timestamped output filename using clock() for reliability
now_time = clock;  % Returns [year month day hour minute seconds]
timestamp_str = sprintf('%04d%02d%02d_%02d%02d%02d', ...
    now_time(1), now_time(2), now_time(3), ...
    now_time(4), now_time(5), floor(now_time(6)));

% ========== CONFIGURATION ==========
base_filename = '1000_1059_2025_11_6_';
hour_start = 16;                        % Starting hour for evaluation loop
separate_hour_minute = '_';
menit_start = 32;                      % Starting minute for evaluation loop
file_extension = '.dat';
num_runs = 30;
output_filename = sprintf('batch_evaluation_results_%s.txt', timestamp_str);

% Initialize output file with header
fid = fopen(output_filename, 'w');
fprintf(fid, '========== BATCH EVALUATION LOG ==========\n');
fprintf(fid, 'Start Time: %04d-%02d-%02d %02d:%02d:%02d\n', ...
    now_time(1), now_time(2), now_time(3), now_time(4), now_time(5), floor(now_time(6)));
fprintf(fid, 'Total Files: %d\n', num_runs);
fprintf(fid, 'File Pattern: %s[HH]_[MM].dat (HH:MM from 16:32 to 17:01)\n', base_filename);
fprintf(fid, 'MATLAB Version: %s\n', version('-release'));
fprintf(fid, '==========================================\n\n');
fclose(fid);

% ========== METRICS COLLECTION ARRAYS ==========
filenames_list = {};
accuracy_hyperbola_data = [];
accuracy_heatmap_data = [];
delay1_data = [];
delay3_data = [];
timing_stability = [];      % |delay1 - delay3|
reliability_data = [];
snr_avg_data = [];
snr_worst_data = [];
ppm_drift_data = [];
mae_hyperbola_data = [];    % MAE for hyperbola estimation
std_hyperbola_data = [];    % Std Dev for hyperbola estimation
mae_heatmap_data = [];      % MAE for heatmap estimation
std_heatmap_data = [];      % Std Dev for heatmap estimation
dist_error_hyperbola_data = [];  % Distance error from HYPERBOLA ESTIMATION
dist_error_heatmap_data = [];    % Distance error from HEATMAP ESTIMATION
status_data = {};
error_messages = {};

success_count = 0;
failed_count = 0;

fprintf('=== Batch Evaluation Started ===\n');
fprintf('Output file: %s\n', output_filename);
fprintf('Running evaluation_main for %d files...\n\n', num_runs);

% ========== MAIN LOOP: DIARY CAPTURE & EVALUATION ==========
% Initialize loop variables from start values
hour = hour_start;
menit = menit_start;

tic;  % Start total batch timer

for i = 1:num_runs
    % Construct filename
    filename = [base_filename num2str(hour) separate_hour_minute num2str(menit) file_extension];
    filenames_list{i} = filename;
    
    % Progress display with estimation
    elapsed_total = toc;
    percent_done = 100*i/num_runs;
    if i > 1
        time_per_file = elapsed_total / i;
        time_remaining = time_per_file * (num_runs - i);
        fprintf('\n═══════════════════════════════════════════════════════════════\n');
        fprintf('[FILE %d/%d] %.1f%% - Processing: %s\n', i, num_runs, percent_done, filename);
        fprintf('Elapsed: %.1f min | Estimated remaining: %.1f min\n', elapsed_total/60, time_remaining/60);
        fprintf('═══════════════════════════════════════════════════════════════\n');
    else
        fprintf('\n═══════════════════════════════════════════════════════════════\n');
        fprintf('[FILE %d/%d] %.1f%% - Processing: %s\n', i, num_runs, percent_done, filename);
        fprintf('═══════════════════════════════════════════════════════════════\n');
    end
    
    try
        % ===== CAPTURE OUTPUT USING EVALC (more reliable than diary) =====
        tic;  % Start evaluation timer
        temp_content = evalc('evaluation_main(filename)');
        elapsed_eval = toc;  % End evaluation timer
        
        % ===== APPEND CAPTURED OUTPUT TO MAIN OUTPUT FILE =====
        fid = fopen(output_filename, 'a');
        fprintf(fid, '========================================\n');
        fprintf(fid, '[FILE %03d/%d] %s\n', i, num_runs, filename);
        fprintf(fid, '========================================\n');
        fprintf(fid, '%s\n\n', temp_content);
        fclose(fid);
        
        % ===== DISPLAY OUTPUT TO CONSOLE (for real-time feedback) =====
        % Print separator and filename
        fprintf('\n───────── [FILE %03d/%d] %s ─────────\n', i, num_runs, filename);
        % Print last 35 lines of evaluation_main output (accuracy, reliability, final results)
        output_lines = strsplit(temp_content, newline);
        % Find and display key results (last ~35 lines which contain final results)
        display_start = max(1, length(output_lines) - 35);
        for j = display_start:length(output_lines)
            if ~isempty(output_lines{j})
                fprintf('%s\n', output_lines{j});
            end
        end
        
        % ===== EXTRACT METRICS FROM TEMP FILE =====
        % Accuracy Hyperbola: pattern "akurasi hyperbola => XX.XX%"
        acc_hyp_match = regexp(temp_content, 'akurasi hyperbola => ([\d.]+)%', 'tokens');
        if ~isempty(acc_hyp_match)
            accuracy_hyperbola_data = [accuracy_hyperbola_data; str2double(acc_hyp_match{1}{1})];
        else
            accuracy_hyperbola_data = [accuracy_hyperbola_data; NaN];
        end
        
        % Accuracy Heatmap: pattern "akurasi heatmap => XX.XX%"
        acc_heat_match = regexp(temp_content, 'akurasi heatmap => ([\d.]+)%', 'tokens');
        if ~isempty(acc_heat_match)
            accuracy_heatmap_data = [accuracy_heatmap_data; str2double(acc_heat_match{1}{1})];
        else
            accuracy_heatmap_data = [accuracy_heatmap_data; NaN];
        end
        
        % Delay1: pattern "raw delay1.*: ([-\d]+)"
        delay1_match = regexp(temp_content, 'raw delay1[^:]*:\s*([-\d]+)', 'tokens');
        if ~isempty(delay1_match)
            delay1_data = [delay1_data; str2double(delay1_match{1}{1})];
        else
            delay1_data = [delay1_data; NaN];
        end
        
        % Delay3: pattern "raw delay3.*: ([-\d]+)"
        delay3_match = regexp(temp_content, 'raw delay3[^:]*:\s*([-\d]+)', 'tokens');
        if ~isempty(delay3_match)
            delay3_data = [delay3_data; str2double(delay3_match{1}{1})];
        else
            delay3_data = [delay3_data; NaN];
        end
        
        % Timing stability: |delay1 - delay3|
        if ~isnan(delay1_data(i)) && ~isnan(delay3_data(i))
            timing_stability = [timing_stability; abs(delay1_data(i) - delay3_data(i))];
        else
            timing_stability = [timing_stability; NaN];
        end
        
        % Reliability: pattern "Total Reliability.*: ([\d.]+)"
        rel_match = regexp(temp_content, 'Total Reliability[^:]*:\s*([\d.]+)', 'tokens');
        if ~isempty(rel_match)
            reliability_data = [reliability_data; str2double(rel_match{1}{1})];
        else
            reliability_data = [reliability_data; NaN];
        end
        
        % SNR extraction: Look for SNR values in all bands
        snr_vals = regexp(temp_content, '(?:Band|SNR)[^\d]*([\d.]+)\s*dB', 'tokens');
        if ~isempty(snr_vals)
            snr_nums = cellfun(@(x) str2double(x{1}), snr_vals);
            snr_avg_data = [snr_avg_data; mean(snr_nums)];
            snr_worst_data = [snr_worst_data; min(snr_nums)];
        else
            snr_avg_data = [snr_avg_data; NaN];
            snr_worst_data = [snr_worst_data; NaN];
        end
        
        % PPM drift: pattern "ppm.*: ([-\d.]+)"
        ppm_match = regexp(temp_content, 'ppm[^:]*:\s*([-\d.]+)', 'tokens');
        if ~isempty(ppm_match)
            ppm_drift_data = [ppm_drift_data; str2double(ppm_match{1}{1})];
        else
            ppm_drift_data = [ppm_drift_data; NaN];
        end
        
        % MAE Hyperbola: pattern "MAE (Mean Absolute Error): XX.XX meters"
        mae_hyp_match = regexp(temp_content, 'MAE\s*\(Mean Absolute Error\):\s*([\d.]+)\s*meters', 'tokens');
        if ~isempty(mae_hyp_match)
            mae_hyperbola_data = [mae_hyperbola_data; str2double(mae_hyp_match{1}{1})];
        else
            mae_hyperbola_data = [mae_hyperbola_data; NaN];
        end
        
        % Std Dev Hyperbola: pattern "Std Dev (Standard Deviation): XX.XX meters"
        std_hyp_match = regexp(temp_content, 'Std Dev\s*\(Standard Deviation\):\s*([\d.]+)\s*meters', 'tokens');
        if ~isempty(std_hyp_match)
            std_hyperbola_data = [std_hyperbola_data; str2double(std_hyp_match{1}{1})];
        else
            std_hyperbola_data = [std_hyperbola_data; NaN];
        end
        
        % MAE Heatmap: pattern "error heatmap => XX.XX meters" (new simplified format)
        mae_heat_matches = regexp(temp_content, 'error heatmap =>\s*([\d.]+)\s*meters', 'tokens');
        if length(mae_heat_matches) >= 2
            mae_heatmap_data = [mae_heatmap_data; str2double(mae_heat_matches{2}{1})];
        elseif length(mae_heat_matches) == 1
            mae_heatmap_data = [mae_heatmap_data; NaN];
        else
            mae_heatmap_data = [mae_heatmap_data; NaN];
        end
        
        % Std Dev Heatmap: pattern "Std Dev (Standard Deviation): XX.XX meters" in heatmap section
        % Get all matches and take the second one (first is from hyperbola, second from heatmap)
        std_heat_matches = regexp(temp_content, 'Std Dev\s*\(Standard Deviation\):\s*([\d.]+)\s*meters', 'tokens');
        if length(std_heat_matches) >= 2
            std_heatmap_data = [std_heatmap_data; str2double(std_heat_matches{2}{1})];
        elseif length(std_heat_matches) == 1
            std_heatmap_data = [std_heatmap_data; NaN];
        else
            std_heatmap_data = [std_heatmap_data; NaN];
        end
        
        % Distance error HYPERBOLA ESTIMATION: pattern "error hyperbola => XX.XX meters" (new simplified format)
        dist_error_hyp_matches = regexp(temp_content, 'error hyperbola =>\s*([\d.]+)\s*meters', 'tokens');
        if ~isempty(dist_error_hyp_matches)
            dist_error_hyperbola_data = [dist_error_hyperbola_data; str2double(dist_error_hyp_matches{1}{1})];
        else
            dist_error_hyperbola_data = [dist_error_hyperbola_data; NaN];
        end
        
        % Distance error HEATMAP ESTIMATION: pattern "error heatmap => XX.XX meters" (new simplified format)
        dist_error_heat_matches = regexp(temp_content, 'error heatmap =>\s*([\d.]+)\s*meters', 'tokens');
        if ~isempty(dist_error_heat_matches)
            dist_error_heatmap_data = [dist_error_heatmap_data; str2double(dist_error_heat_matches{1}{1})];
        else
            dist_error_heatmap_data = [dist_error_heatmap_data; NaN];
        end
        
        % ===== DISPLAY EXTRACTED METRICS SUMMARY =====
        fprintf('\n┌─ METRICS SUMMARY ─────────────────────────────┐\n');
        fprintf('│ Accuracy (Hyperbola): %6.2f%%\n', accuracy_hyperbola_data(i));
        fprintf('│ Accuracy (Heatmap):   %6.2f%%\n', accuracy_heatmap_data(i));
        fprintf('│ MAE Hyperbola:        %6.2f m\n', mae_hyperbola_data(i));
        fprintf('│ Std Dev Hyperbola:    %6.2f m\n', std_hyperbola_data(i));
        fprintf('│ MAE Heatmap:          %6.2f m\n', mae_heatmap_data(i));
        fprintf('│ Std Dev Heatmap:      %6.2f m\n', std_heatmap_data(i));
        fprintf('│ |ΔDelay|:            %6.0f samples\n', timing_stability(i));
        fprintf('│ Reliability:          %6.4f\n', reliability_data(i));
        fprintf('│ Avg SNR:              %6.2f dB\n', snr_avg_data(i));
        fprintf('│ PPM Drift:            %6.3f ppm\n', ppm_drift_data(i));
        fprintf('└─────────────────────────────────────────────┘\n');
        
        status_data{i} = 'OK';
        success_count = success_count + 1;
        
        fprintf('  ✓ Completed in %.2f seconds\n', elapsed_eval);
        
    catch ME
        % Log error to main output file
        fid = fopen(output_filename, 'a');
        fprintf(fid, '========================================\n');
        fprintf(fid, '[FILE %03d/%d] %s [FAILED]\n', i, num_runs, filename);
        fprintf(fid, '========================================\n');
        fprintf(fid, 'ERROR: %s\n', ME.message);
        fprintf(fid, 'Error ID: %s\n', ME.identifier);
        fprintf(fid, '\n');
        fclose(fid);
        
        fprintf('  ✗ Error: %s\n', ME.message);
        
        status_data{i} = 'FAILED';
        error_messages{end+1} = sprintf('%s: %s', filename, ME.message);
        failed_count = failed_count + 1;
        
        % Fill NaN for failed file
        accuracy_hyperbola_data = [accuracy_hyperbola_data; NaN];
        accuracy_heatmap_data = [accuracy_heatmap_data; NaN];
        delay1_data = [delay1_data; NaN];
        delay3_data = [delay3_data; NaN];
        timing_stability = [timing_stability; NaN];
        reliability_data = [reliability_data; NaN];
        snr_avg_data = [snr_avg_data; NaN];
        snr_worst_data = [snr_worst_data; NaN];
        ppm_drift_data = [ppm_drift_data; NaN];
        mae_hyperbola_data = [mae_hyperbola_data; NaN];
        std_hyperbola_data = [std_hyperbola_data; NaN];
        mae_heatmap_data = [mae_heatmap_data; NaN];
        std_heatmap_data = [std_heatmap_data; NaN];
        dist_error_hyperbola_data = [dist_error_hyperbola_data; NaN];
        dist_error_heatmap_data = [dist_error_heatmap_data; NaN];
    end
    
    fprintf('\n');
    
    % Increment time counters
    menit = menit + 1;
    if (menit == 60)
        hour = hour + 1;
        menit = 0;
    end
end

total_time = toc;

% ========== METRICS EXTRACTION & SUMMARY TABLE ==========
% Append summary table to output file
fid = fopen(output_filename, 'a');

fprintf(fid, '\n\n');
fprintf(fid, '========== SUMMARY METRICS TABLE ==========\n\n');

% Column headers
fprintf(fid, '%-25s | %12s | %12s | %8s | %11s | %9s | %9s | %13s | %13s | %9s | %8s\n', ...
    'Filename', 'Acc_Hyperbola', 'Acc_Heatmap', '|ΔDelay|', 'Reliability', 'Avg_SNR', 'Worst_SNR', 'DistErr_Hyp', 'DistErr_Heat', 'PPM_Drift', 'Status');
fprintf(fid, '%s\n', repmat('-', 160, 1));

% Data rows
for i = 1:num_runs
    % Extract just the time part from filename (HH_MM)
    fname_short = filenames_list{i}(end-8:end-4);  % Extract "HH_MM" from filename
    
    acc_hyp_str = sprintf('%.2f%%', accuracy_hyperbola_data(i));
    if isnan(accuracy_hyperbola_data(i))
        acc_hyp_str = '0.00%';
    end
    
    acc_heat_str = sprintf('%.2f%%', accuracy_heatmap_data(i));
    if isnan(accuracy_heatmap_data(i))
        acc_heat_str = '0.00%';
    end
    
    delta_str = sprintf('%d', round(timing_stability(i)));
    if isnan(timing_stability(i))
        delta_str = 'N/A';
    end
    
    rel_str = sprintf('%.4f', reliability_data(i));
    if isnan(reliability_data(i))
        rel_str = 'N/A';
    end
    
    snr_avg_str = sprintf('%.2f dB', snr_avg_data(i));
    if isnan(snr_avg_data(i))
        snr_avg_str = 'N/A';
    end
    
    snr_worst_str = sprintf('%.2f dB', snr_worst_data(i));
    if isnan(snr_worst_data(i))
        snr_worst_str = 'N/A';
    end
    
    ppm_str = sprintf('%.3f', ppm_drift_data(i));
    if isnan(ppm_drift_data(i))
        ppm_str = 'N/A';
    end
    
    dist_err_hyp_str = sprintf('%.1f m', dist_error_hyperbola_data(i));
    if isnan(dist_error_hyperbola_data(i))
        dist_err_hyp_str = 'N/A';
    end
    
    dist_err_heat_str = sprintf('%.1f m', dist_error_heatmap_data(i));
    if isnan(dist_error_heatmap_data(i))
        dist_err_heat_str = 'N/A';
    end
    
    fprintf(fid, '%-25s | %12s | %12s | %8s | %11s | %9s | %9s | %13s | %13s | %9s | %8s\n', ...
        fname_short, acc_hyp_str, acc_heat_str, delta_str, rel_str, snr_avg_str, snr_worst_str, dist_err_hyp_str, dist_err_heat_str, ppm_str, status_data{i});
end

% ========== SUMMARY STATISTICS ==========
fprintf(fid, '%s\n\n', repmat('-', 120, 1));
fprintf(fid, 'SUMMARY STATISTICS:\n');
fprintf(fid, '==================\n\n');

% Accuracy Hyperbola statistics
valid_acc_hyp = accuracy_hyperbola_data;
valid_acc_hyp(isnan(valid_acc_hyp)) = 0;
if ~isempty(valid_acc_hyp)
    fprintf(fid, 'Accuracy Hyperbola (%%): Mean=%.2f, Median=%.2f, Min=%.2f, Max=%.2f, StdDev=%.2f\n', ...
        mean(valid_acc_hyp), median(valid_acc_hyp), min(valid_acc_hyp), max(valid_acc_hyp), std(valid_acc_hyp));
end

% Accuracy Heatmap statistics
valid_acc_heat = accuracy_heatmap_data;
valid_acc_heat(isnan(valid_acc_heat)) = 0;
if ~isempty(valid_acc_heat)
    fprintf(fid, 'Accuracy Heatmap (%%):   Mean=%.2f, Median=%.2f, Min=%.2f, Max=%.2f, StdDev=%.2f\n', ...
        mean(valid_acc_heat), median(valid_acc_heat), min(valid_acc_heat), max(valid_acc_heat), std(valid_acc_heat));
end

% Timing stability statistics
valid_timing = timing_stability(~isnan(timing_stability));
if ~isempty(valid_timing)
    fprintf(fid, '|ΔDelay| (samples): Mean=%.1f, Median=%.1f, Min=%.0f, Max=%.0f, StdDev=%.1f\n', ...
        mean(valid_timing), median(valid_timing), min(valid_timing), max(valid_timing), std(valid_timing));
end

% Reliability statistics
valid_rel = reliability_data(~isnan(reliability_data));
if ~isempty(valid_rel)
    fprintf(fid, 'Reliability: Mean=%.4f, Median=%.4f, Min=%.4f, Max=%.4f, StdDev=%.4f\n', ...
        mean(valid_rel), median(valid_rel), min(valid_rel), max(valid_rel), std(valid_rel));
end

% SNR statistics
valid_snr_avg = snr_avg_data(~isnan(snr_avg_data));
if ~isempty(valid_snr_avg)
    fprintf(fid, 'Avg SNR (dB): Mean=%.2f, Median=%.2f, Min=%.2f, Max=%.2f, StdDev=%.2f\n', ...
        mean(valid_snr_avg), median(valid_snr_avg), min(valid_snr_avg), max(valid_snr_avg), std(valid_snr_avg));
end

% PPM drift statistics
valid_ppm = ppm_drift_data(~isnan(ppm_drift_data));
if ~isempty(valid_ppm)
    fprintf(fid, 'PPM Drift: Mean=%.3f, Median=%.3f, Min=%.3f, Max=%.3f, StdDev=%.3f\n', ...
        mean(valid_ppm), median(valid_ppm), min(valid_ppm), max(valid_ppm), std(valid_ppm));
end

% MAE Hyperbola statistics
valid_mae_hyp = mae_hyperbola_data(~isnan(mae_hyperbola_data));
if ~isempty(valid_mae_hyp)
    fprintf(fid, '\nMAE Hyperbola (m): Mean=%.2f, Median=%.2f, Min=%.2f, Max=%.2f, StdDev=%.2f\n', ...
        mean(valid_mae_hyp), median(valid_mae_hyp), min(valid_mae_hyp), max(valid_mae_hyp), std(valid_mae_hyp));
end

% Std Dev Hyperbola statistics
valid_std_hyp = std_hyperbola_data(~isnan(std_hyperbola_data));
if ~isempty(valid_std_hyp)
    fprintf(fid, 'Std Dev Hyperbola (m): Mean=%.2f, Median=%.2f, Min=%.2f, Max=%.2f, StdDev=%.2f\n', ...
        mean(valid_std_hyp), median(valid_std_hyp), min(valid_std_hyp), max(valid_std_hyp), std(valid_std_hyp));
end

% MAE Heatmap statistics
valid_mae_heat = mae_heatmap_data(~isnan(mae_heatmap_data));
if ~isempty(valid_mae_heat)
    fprintf(fid, 'MAE Heatmap (m): Mean=%.2f, Median=%.2f, Min=%.2f, Max=%.2f, StdDev=%.2f\n', ...
        mean(valid_mae_heat), median(valid_mae_heat), min(valid_mae_heat), max(valid_mae_heat), std(valid_mae_heat));
end

% Std Dev Heatmap statistics
valid_std_heat = std_heatmap_data(~isnan(std_heatmap_data));
if ~isempty(valid_std_heat)
    fprintf(fid, 'Std Dev Heatmap (m): Mean=%.2f, Median=%.2f, Min=%.2f, Max=%.2f, StdDev=%.2f\n', ...
        mean(valid_std_heat), median(valid_std_heat), min(valid_std_heat), max(valid_std_heat), std(valid_std_heat));
end

% Distance Error Hyperbola statistics
valid_dist_err_hyp = dist_error_hyperbola_data(~isnan(dist_error_hyperbola_data));
if ~isempty(valid_dist_err_hyp)
    fprintf(fid, '\nDistance Error Hyperbola (m): Mean=%.2f, Median=%.2f, Min=%.2f, Max=%.2f, StdDev=%.2f\n', ...
        mean(valid_dist_err_hyp), median(valid_dist_err_hyp), min(valid_dist_err_hyp), max(valid_dist_err_hyp), std(valid_dist_err_hyp));
end

% Distance Error Heatmap statistics
valid_dist_err_heat = dist_error_heatmap_data(~isnan(dist_error_heatmap_data));
if ~isempty(valid_dist_err_heat)
    fprintf(fid, 'Distance Error Heatmap (m): Mean=%.2f, Median=%.2f, Min=%.2f, Max=%.2f, StdDev=%.2f\n', ...
        mean(valid_dist_err_heat), median(valid_dist_err_heat), min(valid_dist_err_heat), max(valid_dist_err_heat), std(valid_dist_err_heat));
end

fprintf(fid, '\n');

% ========== COMPLETION SUMMARY ==========
fprintf(fid, 'Completion Summary:\n');
fprintf(fid, '===================\n');
fprintf(fid, 'Total Files Processed: %d\n', num_runs);
fprintf(fid, 'Successful: %d\n', success_count);
fprintf(fid, 'Failed: %d\n', failed_count);
fprintf(fid, 'Total Runtime: %.2f seconds (%.2f minutes)\n', total_time, total_time/60);

if failed_count > 0
    fprintf(fid, '\nFailed Files:\n');
    for i = 1:length(error_messages)
        fprintf(fid, '  - %s\n', error_messages{i});
    end
end

fprintf(fid, '\nEnd Time: %s\n', datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

fclose(fid);

% ========== CONSOLE OUTPUT SUMMARY ==========
fprintf('\n=== Batch Evaluation Completed ===\n');
fprintf('Total files processed: %d\n', num_runs);
fprintf('Successful: %d\n', success_count);
fprintf('Failed: %d\n', failed_count);
fprintf('Total runtime: %.2f seconds (%.2f minutes)\n', total_time, total_time/60);
fprintf('\nOutput file: %s\n', output_filename);
fprintf('File location: %s\n', pwd);

if failed_count > 0
    fprintf('\nFailed files:\n');
    for i = 1:length(error_messages)
        fprintf('  - %s\n', error_messages{i});
    end
end

fprintf('\n=== Ready for analysis! ===\n');