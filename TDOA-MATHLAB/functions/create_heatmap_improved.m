function [ heat_long, heat_lat, mse_doa, start_lat, stop_lat, start_long, stop_long ] = create_heatmap_improved( doa_meters12, doa_meters13, doa_meters23, rx1_lat, rx1_long, rx2_lat, rx2_long, rx3_lat, rx3_long, resolution, geo_ref_lat, geo_ref_long, reliability12, reliability13, reliability23 )
%create_heatmap_improved: Creates an improved heatmap with adaptive weighting and outlier rejection
%
%   IMPROVEMENTS over original create_heatmap:
%   1. Adaptive weighting based on correlation reliability
%   2. Outlier detection and rejection
%   3. GDOP (Geometric Dilution of Precision) consideration
%   4. Spatial smoothing for noise reduction
%
%   Additional inputs:
%   reliability12, reliability13, reliability23: correlation reliabilities (0..1)

disp('creating IMPROVED heatmap with adaptive weighting...');

num_points = resolution; % points in one dimension (creates squared area)

% Define area for heatmap display
lat_span = 0.03;
start_lat = geo_ref_lat - lat_span;
stop_lat  = geo_ref_lat + lat_span;

long_span = 0.03;
start_long = geo_ref_long - long_span;
stop_long  = geo_ref_long + long_span;

% Create heatmap grid
heat_lat  = linspace(start_lat,  stop_lat,  num_points);
heat_long = linspace(start_long, stop_long, num_points);
mse_doa = zeros(num_points, num_points);

%% IMPROVEMENT 1: Outlier Detection
reliabilities = [reliability12, reliability13, reliability23];
median_rel = median(reliabilities);
outlier_threshold = 0.4 * median_rel; % Aggressive outlier threshold

% Detect outliers
valid_mask = reliabilities > outlier_threshold;
num_valid = sum(valid_mask);

disp(' ');
disp('=== ADAPTIVE WEIGHTING ANALYSIS ===');
disp(['Reliability 1-2: ' num2str(reliability12, '%.4f') ' - ' char(ternary(valid_mask(1), '✓ VALID', '✗ OUTLIER'))]);
disp(['Reliability 1-3: ' num2str(reliability13, '%.4f') ' - ' char(ternary(valid_mask(2), '✓ VALID', '✗ OUTLIER'))]);
disp(['Reliability 2-3: ' num2str(reliability23, '%.4f') ' - ' char(ternary(valid_mask(3), '✓ VALID', '✗ OUTLIER'))]);
disp(['Outlier threshold: ' num2str(outlier_threshold, '%.4f')]);
disp(['Valid hyperbolas: ' num2str(num_valid) '/3']);

% Check if we have enough valid data
if num_valid == 0
    warning('⚠️  All hyperbolas flagged as outliers! Using all data with equal weights.');
    valid_mask = [true, true, true];
    num_valid = 3;
end

%% IMPROVEMENT 2: Adaptive Exponential Weighting
% Use exponential weighting to heavily emphasize high-reliability measurements
% Formula: weight = exp(k * (reliability - 0.5))
% where k controls the steepness (higher k = more aggressive weighting)
k = 10;  % Steepness parameter

weights = exp(k * (reliabilities - 0.5));
weights = weights .* valid_mask;  % Zero weight for outliers

% Normalize weights
if sum(weights) > 0
    weights = weights / sum(weights);
else
    weights = [1/3, 1/3, 1/3];  % Fallback to equal weights
end

disp(' ');
disp('=== NORMALIZED WEIGHTS ===');
disp(['Weight 1-2: ' num2str(weights(1), '%.4f') ' (' num2str(weights(1)*100, '%.1f') '%)']);
disp(['Weight 1-3: ' num2str(weights(2), '%.4f') ' (' num2str(weights(2)*100, '%.1f') '%)']);
disp(['Weight 2-3: ' num2str(weights(3), '%.4f') ' (' num2str(weights(3)*100, '%.1f') '%)']);
disp(' ');

%% IMPROVEMENT 3: Calculate Weighted MSE with GDOP consideration
for lat_idx = 1:num_points
    for long_idx = 1:num_points
        % Calculate distances from current point to all receivers
        dist_to_rx1 = dist_latlong(heat_lat(lat_idx), heat_long(long_idx), rx1_lat, rx1_long, geo_ref_lat, geo_ref_long);
        dist_to_rx2 = dist_latlong(heat_lat(lat_idx), heat_long(long_idx), rx2_lat, rx2_long, geo_ref_lat, geo_ref_long);
        dist_to_rx3 = dist_latlong(heat_lat(lat_idx), heat_long(long_idx), rx3_lat, rx3_long, geo_ref_lat, geo_ref_long);
        
        % Calculate theoretical DOAs for this point
        current_doa12 = dist_to_rx1 - dist_to_rx2;
        current_doa13 = dist_to_rx1 - dist_to_rx3;
        current_doa23 = dist_to_rx2 - dist_to_rx3;
        
        % Calculate GDOP weights (geometric strength)
        gdop12 = calculate_gdop_weight(rx1_lat, rx1_long, rx2_lat, rx2_long, heat_lat(lat_idx), heat_long(long_idx));
        gdop13 = calculate_gdop_weight(rx1_lat, rx1_long, rx3_lat, rx3_long, heat_lat(lat_idx), heat_long(long_idx));
        gdop23 = calculate_gdop_weight(rx2_lat, rx2_long, rx3_lat, rx3_long, heat_lat(lat_idx), heat_long(long_idx));
        
        % Combined weights: reliability * GDOP
        combined_weights = weights .* [gdop12, gdop13, gdop23];
        combined_weights = combined_weights / sum(combined_weights);  % Renormalize
        
        % Weighted MSE calculation
        doa_error = combined_weights(1) * (current_doa12 - doa_meters12)^2 + ...
            combined_weights(2) * (current_doa13 - doa_meters13)^2 + ...
            combined_weights(3) * (current_doa23 - doa_meters23)^2;
        
        mse_doa(long_idx, lat_idx) = doa_error;
    end
end

%% IMPROVEMENT 4: Spatial Smoothing
% Apply Gaussian smoothing to reduce noise and create smoother heatmap
% Only apply if resolution is high enough
if num_points >= 50
    sigma = max(1, num_points / 100);  % Adaptive sigma based on resolution
    disp(['Applying Gaussian smoothing (sigma = ' num2str(sigma, '%.2f') ')...']);
    
    % Smooth the error map before inversion
    mse_doa_smoothed = imgaussfilt(mse_doa, sigma);
    mse_doa = mse_doa_smoothed;
else
    disp('Skipping spatial smoothing (resolution too low)...');
end

% Invert MSE to get confidence values (lower error = higher confidence)
mse_doa = 1 ./ mse_doa;

% Normalize to 0-1 range
mse_doa = mse_doa .* (1 / max(max(mse_doa)));

disp(' ');
disp(['Heatmap max confidence: ' num2str(max(max(mse_doa)), '%.6f')]);
disp(['Heatmap mean confidence: ' num2str(mean(mean(mse_doa)), '%.6f')]);
disp(' ');
disp('✓ IMPROVED heatmap generation complete!');
end


%% Helper Function: Calculate GDOP Weight
function gdop_weight = calculate_gdop_weight(rx1_lat, rx1_long, rx2_lat, rx2_long, est_lat, est_long)
% Calculate geometric strength based on angle between receiver baseline
% and position vector. Better geometry (closer to perpendicular) = higher weight

% Calculate vectors
baseline_vector = [rx2_lat - rx1_lat, rx2_long - rx1_long];
position_vector = [est_lat - rx1_lat, est_long - rx1_long];

% Handle edge case: point is at receiver location
if norm(position_vector) < 1e-6
    gdop_weight = 0.5;  % Medium weight for points at receiver
    return;
end

% Calculate angle between vectors
cos_angle = dot(baseline_vector, position_vector) / (norm(baseline_vector) * norm(position_vector));
cos_angle = max(-1, min(1, cos_angle));  % Clamp to valid range
angle = acos(cos_angle);

% Optimal angle is 90 degrees (perpendicular)
% Calculate angular error from optimal
angle_error = abs(angle - pi/2);

% Convert to weight (0-1, where 1 is best geometry)
% Using Gaussian-like function centered at 90 degrees
gdop_weight = exp(-angle_error^2 / 0.5);
end


%% Helper Function: Ternary operator simulation
function result = ternary(condition, true_value, false_value)
if condition
    result = true_value;
else
    result = false_value;
end
end
