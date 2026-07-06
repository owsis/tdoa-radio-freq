function [snr_db, snr_linear, signal_power, noise_power, quality] = estimate_snr_iq(signal_iq, varargin)
% =========================================================================
% ESTIMATE SNR from IQ Signal
%
% Analyzes complex I/Q signal to estimate signal-to-noise ratio using
% power-based method and provides quality assessment.
%
% INPUT:
%   signal_iq:  Complex I/Q signal (N×1)
%   varargin:   Optional name-value pairs (currently unused, for future)
%
% OUTPUT:
%   snr_db:        SNR in decibels (dB)
%   snr_linear:    SNR in linear ratio
%   signal_power:  Estimated signal power
%   noise_power:   Estimated noise power
%   quality:       String quality: 'EXCELLENT', 'GOOD', 'POOR', 'CRITICAL'
%
% THEORY:
% 1. Calculate instantaneous power: P(n) = |I(n) + jQ(n)|^2
% 2. Signal power = mean of top 50% power values
% 3. Noise power = mean of bottom 10% power values
% 4. SNR = signal_power / noise_power
% 5. SNR_dB = 10 * log10(SNR)
%
% QUALITY THRESHOLDS:
%   EXCELLENT: SNR > 30 dB  (signal ~1000x noise)
%   GOOD:      SNR 15-30 dB (signal ~32-1000x noise)
%   POOR:      SNR 5-15 dB  (signal ~3-32x noise)
%   CRITICAL:  SNR < 5 dB   (signal barely above noise)
%
% EXAMPLE:
%   [snr_db, snr_lin, sig_pow, noi_pow, qual] = estimate_snr_iq(iq_signal);
%   fprintf('SNR = %.1f dB (%s)\n', snr_db, qual);
%
% =========================================================================

% =====================================================================
% Input Validation
% =====================================================================

if ~isvector(signal_iq)
    signal_iq = signal_iq(:);
end

signal_iq = complex(signal_iq(:));  % Ensure complex column vector

if isempty(signal_iq) || length(signal_iq) < 100
    error('Signal must contain at least 100 samples');
end

% =====================================================================
% Power-Based SNR Estimation (Most Reliable Method)
% =====================================================================

% Step 1: Calculate instantaneous power from I/Q samples
% Power = |complex_signal|^2 = I^2 + Q^2
power_inst = abs(signal_iq) .^ 2;

% Step 2: Sort power values in descending order
% This helps identify signal vs noise regions
power_sorted = sort(power_inst, 'descend');

% Step 3: Signal power estimation
% Use top 50% of power values (where signal+noise dominates)
idx_signal_end = round(length(power_inst) * 0.5);
signal_power = mean(power_sorted(1:idx_signal_end));

% Step 4: Noise power estimation
% Use bottom 10% of power values (where only noise exists)
idx_noise_start = length(power_inst) - round(length(power_inst) * 0.1);
noise_power = mean(power_sorted(idx_noise_start:end));

% Step 5: Calculate SNR
if noise_power > 0
    snr_linear = signal_power / noise_power;
    snr_db = 10 * log10(snr_linear);
else
    % Edge case: no noise detected
    snr_db = 100;
    snr_linear = 1e4;
end

% Ensure SNR is reasonable
if snr_db > 100
    snr_db = 100;
end
if snr_db < -30
    snr_db = -30;
end

% =====================================================================
% Quality Assessment
% =====================================================================

if snr_db >= 30
    quality = 'EXCELLENT';
elseif snr_db >= 15
    quality = 'GOOD';
elseif snr_db >= 5
    quality = 'POOR';
else
    quality = 'CRITICAL';
end

end
