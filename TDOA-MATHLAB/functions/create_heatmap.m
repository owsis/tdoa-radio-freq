function [ heat_long, heat_lat, mse_doa, start_lat, stop_lat, start_long, stop_long ] = create_heatmap( doa_meters12, doa_meters13, doa_meters23, rx1_lat, rx1_long, rx2_lat, rx2_long, rx3_lat, rx3_long, resolution, geo_ref_lat, geo_ref_long )
%create_heatmap_kl Creates a heatmap for based on Mean Squared Error (MSE)

%    returns: 
%    heat_long: longitudes of heatmap points
%    heat_lat: latitudes of heatmap points
%    mse_doa: heatmap magnitudes

    disp('creating heatmap... ');

    num_points = resolution; % points in one dimension (creates squared area)

    % Scope area yang akan dibuat heatmap
    % defines the area, where the heatmap is displayed (around the geodetic
    % reference point)
    % geo_ref_lat = mean(rx1_lat, rx2_lat, rx3_lat)
    % geo_ref_long = mean(rx1_long, rx2_long, rx3_long)
    lat_span = 0.03;
    start_lat = geo_ref_lat - lat_span;
    stop_lat  = geo_ref_lat + lat_span;
    % disp(['start_lat =>', num2str(start_lat, 8)]);
    % disp(['stop_lat =>', num2str(stop_lat, 8)]);
    
    long_span = 0.03;
    start_long = geo_ref_long - long_span;
    stop_long  = geo_ref_long + long_span;
    % disp(['start_long =>', num2str(start_long, 8)]);
    % disp(['stop_long =>', num2str(stop_long, 8)]);
    
    % create heatmap
    heat_lat  = linspace(start_lat,  stop_lat,  num_points);
    heat_long = linspace(start_long, stop_long, num_points);
    mse_doa = zeros(num_points, num_points);
    
    for lat_idx = 1:num_points
        for long_idx = 1:num_points
            % calculate mean squared error of current point in terms of tdoa

            % distance current point to receivers
            dist_to_rx1 = dist_latlong( heat_lat(lat_idx), heat_long(long_idx), rx1_lat, rx1_long, geo_ref_lat, geo_ref_long );
            dist_to_rx2 = dist_latlong( heat_lat(lat_idx), heat_long(long_idx), rx2_lat, rx2_long, geo_ref_lat, geo_ref_long );
            dist_to_rx3 = dist_latlong( heat_lat(lat_idx), heat_long(long_idx), rx3_lat, rx3_long, geo_ref_lat, geo_ref_long );
            
            % current doa in meters
            current_doa12 = dist_to_rx1 - dist_to_rx2;
            current_doa13 = dist_to_rx1 - dist_to_rx3;
            current_doa23 = dist_to_rx2 - dist_to_rx3;
            
            % error doa
            % Rumus MSE, example value:
            % current_doa = [10, 20, 30]
            % doa_meter = [8, 18, 28]
            % doa_error = (10-8)^2 + (20-18)^2 + (30-28)^2
            % doa_error = 4 + 4 + 4
            % doa_error = 12
            doa_error = (current_doa12 - doa_meters12)^2 + (current_doa13 - doa_meters13)^2 + (current_doa23 - doa_meters23)^2;
            mse_doa(long_idx, lat_idx) = doa_error;
        end
    end
    
    % Real-case with 2x2 matrix (heatmap_resolution = 2)
    % mse_doa = [
    %   [201260000, 45180000], 
    %   [12980000, 55810000]
    % ]
    % disp(mse_doa);

    % setiap value pada mse_doa dibagi dengan 1
    % 1/[value_mse_doa]
    mse_doa = 1./mse_doa;

    % mse_doa = [
    %   [0,000000004968697, 0,000000022133687],
    %   [0,000000077041602, 0,000000017917936]
    % ]
    % disp('mse_doa = 1./mse_doa');
    % disp(mse_doa);

    disp(' ');
    disp(['max(mse_doa) =>', num2str(max(mse_doa))]);               
    % ex 2x2 => max(mse_doa) = [0,000000077041602, 0,000000022133687]
    disp(['max(max(mse_doa)) =>', num2str(max(max(mse_doa)))]);    
    % ex 2x2 => max(max(mse_doa)) = [0,000000077041602]
    disp(['1/max(max(mse_doa)) =>', num2str(1/max(max(mse_doa)))]); 
    % ex 2x2 => 1/max(max(mse_doa)) = 12980000,0783992
    disp(' ');

    mse_doa = mse_doa .* (1/max(max(mse_doa)));
    % mse_doa = [
    %   [0,06449368745, 0,287295259]
    %   [1, 0,2325748107]
    % ]
    % disp(mse_doa);

    disp('creating heatmap done! ');
end

