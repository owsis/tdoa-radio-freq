function [ points_lat, points_long ] = gen_hyperbola_improved( doa_meters, rx1_lat, rx1_long, rx2_lat, rx2_long, geo_ref_lat, geo_ref_long, rx1_name, rx2_name)
%gen_hyperbola_improved: Enhanced version with extended range and adaptive step size
%   Generates hyperbola points from receiver positions and TDOA in meters
%   Improvements:
%   1. Extended range based on baseline distance
%   2. Adaptive step size for extreme TDOA values
%   3. Better handling of edge cases


% Convert to xy coordinates
[rx1_x, rx1_y] = latlong2xy(rx1_lat, rx1_long, geo_ref_lat, geo_ref_long);
[rx2_x, rx2_y] = latlong2xy(rx2_lat, rx2_long, geo_ref_lat, geo_ref_long);


% Calculate triangle with cosine rule
rx_x_dist = rx2_x - rx1_x;
rx_y_dist = rx2_y - rx1_y;

rx_dist_complex = rx_x_dist + i*rx_y_dist;
dist_12 = abs(rx_dist_complex);  % positions in complex plane
angle_12 = angle(rx_dist_complex); % -pi to +pi
disp(['rx_dist_complex: ', num2str(rx_dist_complex)]);
disp(['Distance between RX1(' num2str(rx1_lat) ', ' num2str(rx1_long) ') and RX2(' num2str(rx2_lat) ', ' num2str(rx2_long) '): ' num2str(dist_12) ' km, angle: ' num2str(angle_12) ' rad']);

hyp_x = zeros(1,1);
hyp_y = zeros(1,1);

hyp_x_leg1 = zeros(1,1);
hyp_y_leg1 = zeros(1,1);
hyp_x_leg2 = zeros(1,1);
hyp_y_leg2 = zeros(1,1);
hyp_point_counter = 0;

% Calculate TDOA ratio for diagnostics
tdoa_ratio = abs(doa_meters/1000) / dist_12;
disp(['TDOA/Baseline ratio: ' num2str(tdoa_ratio*100, '%.1f') '%']);

if abs(doa_meters/1000) > dist_12
    disp(['<strong>TDOA delay (' num2str(doa_meters) ' meters) larger than RX distance (' num2str(1000 * dist_12) ' meters) -> no solution possible </strong>']);
    doa_meters = sign(doa_meters) * 0.995 * dist_12 * 1000;
    disp(['<strong>ATTENTION: Correcting TDOA delay to 0.995 * RX distance (maximum possible value) = ' num2str(doa_meters) ' meters</strong>']);
end


if abs(doa_meters/1000) <= dist_12
    
    % IMPROVEMENT 1: Adaptive step size based on TDOA ratio
    if tdoa_ratio > 0.3
        step_size = 0.01;  % 10 meters for extreme TDOA
        disp('Using fine step size (0.01 km) for extreme TDOA ratio');
    elseif tdoa_ratio > 0.15
        step_size = 0.025; % 25 meters for moderate TDOA
        disp('Using medium step size (0.025 km) for moderate TDOA ratio');
    else
        step_size = 0.05;  % 50 meters for normal TDOA
    end
    
    % IMPROVEMENT 2: Extended range based on baseline distance
    % Range should be at least 1.5x baseline or 20 km, whichever is larger
    max_range = max(20, dist_12 * 1.5);
    disp(['Hyperbola generation range: 0 to ' num2str(max_range, '%.1f') ' km, step: ' num2str(step_size*1000, '%.0f') ' m']);
    
    % Generate hyperbola points
    for r_1 = 0:step_size:max_range
        r_2 = r_1 - doa_meters/1000;
        
        if ((r_2 + r_1) > dist_12)  % Triangle inequality check
            
            acos_argument = (r_2^2 - r_1^2 - dist_12^2) / (-2*r_1*dist_12); % Cosine theorem
            
            if (acos_argument >= -1) && (acos_argument <= +1) % Valid triangle check
                
                hyp_point_counter = hyp_point_counter + 1;
                
                hyp_angle = acos(acos_argument); % Inner angle of triangle at RX1
                
                abs_angle1 = wrap2pi(angle_12 + hyp_angle);  % 1st solution: hyperbola leg 1
                hyp_x_leg1(hyp_point_counter) = rx1_x + r_1 * cos(abs_angle1);
                hyp_y_leg1(hyp_point_counter) = rx1_y + r_1 * sin(abs_angle1);
                
                abs_angle2 = wrap2pi(angle_12 - hyp_angle);  % 2nd solution: hyperbola leg 2
                hyp_x_leg2(hyp_point_counter) = rx1_x + r_1 * cos(abs_angle2);
                hyp_y_leg2(hyp_point_counter) = rx1_y + r_1 * sin(abs_angle2);
            end
        end
        
    end
else
    disp('TDOA delay larger than RX distance -> no solution possible');
end

if (hyp_point_counter == 0)
    disp('<strong>WARNING: Hyperbola could not be constructed - no valid points found!</strong>');
end

hyp_x = [fliplr(hyp_x_leg1) hyp_x_leg2];
hyp_y = [fliplr(hyp_y_leg1) hyp_y_leg2];
hyp_points = 2 * hyp_point_counter; % x2 because there are 2 angles: abs_angle1 and abs_angle2


points_lat = zeros(hyp_points,1);
points_long = zeros(hyp_points,1);

for ii=1:1:hyp_points
    [points_lat(ii), points_long(ii)] = xy2latlong(hyp_x(ii), hyp_y(ii), geo_ref_lat, geo_ref_long);
end

disp(['Hyperbola with totally ' num2str(hyp_points) ' points generated.']);

% IMPROVEMENT 3: Warning for insufficient points
if hyp_points < 100
    disp(['<strong>WARNING: Only ' num2str(hyp_points) ' points generated. This may indicate:</strong>']);
    disp('  - TDOA value too large relative to baseline distance');
    disp('  - Poor correlation reliability');
    disp('  - Consider using weighted intersection or excluding this hyperbola');
end
end
