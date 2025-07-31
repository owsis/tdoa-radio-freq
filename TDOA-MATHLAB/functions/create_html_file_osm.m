function [ output_args ] = create_html_file_osm( filename, rx_lat, rx_long, hyperbola_lat, hyperbola_long, heatmap_cell, heatmap_threshold )
%CREATE_HTML_FILE   Generates the html code for open street map showing RX
%                   positions and the hyperbolas
%
%   rx_lat:         list of latitudes for RX positions (for displaying receiver positions)
%   rx_long:        list of longitudes for RX positions
%   hyperbola_lat:  cell array of latitudes for RX positions (one cell array elements correspond to one hyperbola)
%   hyperbola_long: cell array of longitudes for RX positions (one cell array elements correspond to one hyperbola)
%   heatmap_cell:   CURRENTLY NOT SUPPORTED cell array, that contains
%                   {1} = long vector,
%                   {2} = lat vector and
%                   {3} = magnitude of heatmap points vector
%                   {4} = start_lat (scope area heatmap)
%                   {5} = stop_lat (scope area heatmap)
%                   {6} = start_long (scope area heatmap)
%                   {7} = stop_long (scope area heatmap)

disp('writing html for OSM... ');

% consistency checks
if ~iscell(heatmap_cell)
    error('Parameter heatmap_cell needs to be a cell array with long, lat and magnitude');
end

if size(heatmap_cell) ~= 7
    error('Parameter heatmap_cell needs to be a cell array with long, lat and magnitude');
end


if ~iscell(hyperbola_lat) || ~iscell(hyperbola_long)
    error('Parameter hyperbola_lat, hyperbola_long need to be cell arrays');
end

if length(hyperbola_lat) ~= length(hyperbola_long)
    error('Length of hyperbola latitude and longitude values do not match');
end

for ii=1:length(hyperbola_lat)
    if length(cell2mat(hyperbola_lat(ii))) ~= length(cell2mat(hyperbola_long(ii)))
        error(['Length of hyperbola latitude and longitude in cell array doesn not for hyperbola ' num2str(ii)]);
    end
end

if size(rx_lat) ~= size(rx_long)
    error('Dimensions of rx latitude and longitude values do not match');
end


num_rx_positions = length(rx_lat);

num_hyperbolas = length(hyperbola_lat);  % length of cell array

num_hyperb_points = zeros(1, num_hyperbolas);
for ii = 1:num_hyperbolas
    num_hyperb_points(ii) = length(hyperbola_lat{ii}); % length of each vector in the cell array
end


%% generate html code
disp(['write html to file: ' filename]);

fid = fopen(filename,'w');
if fid == -1
    error('Gagal membuka file. Periksa izin atau lokasi file.');
end

fprintf(fid, [...
    '<!DOCTYPE html>\n'...
    '<html>\n'...
    '\n'...
    '<head>\n'...
    '<title>Simple Leaflet Map</title>\n'...
    '<meta charset="utf-8" />\n'...
    '<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""\n'...
    '</head>\n'...
    '\n'...
    '<body>\n'...
    '\n'...
    '<div id="map" style="width:100%%;height:890px"></div>\n'...
    '\n'...
    '<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""> </script>\n'...
    '\n'...
    '<script src="leaflet-heat.js"> </script>\n'... % Add by Siswo
    '\n'... % Add by Siswo
    '<script>\n'...
    '  var map = L.map("map").setView([ ' num2str(mean(rx_lat), 8) ', ' num2str(mean(rx_long), 8) '], 13); \n'...
    '  mapLink = \''<a href="http://openstreetmap.org">OpenStreetMap</a>\'';\n'...
    ' \n'...
    '  L.tileLayer(\n'...
    '    "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {\n'...
    '	  attribution: "Map data &copy; " + mapLink,\n'...
    '	  maxZoom: 18,\n'...
    '	  }).addTo(map)\n'...
    '  L.control.scale().addTo(map);\n'...
    ]);

fprintf(fid, '\n');

fprintf(fid, ['  var targetPointIcon = L.icon({ \n'...
    '                            iconUrl: \'' assets/target-point.png \'', \n'...
    '                            iconSize: [60, 50], \n'...
    '                            iconAnchor: [18, 50], \n'...
    '                            popupAnchor:  [-3, -53] }); \n\n']);
fprintf(fid, ['  var hasilPointIcon = L.icon({ \n'...
    '                            iconUrl: \'' assets/hasil-point.png \'', \n'...
    '                            iconSize: [60, 47], \n'...
    '                            iconAnchor: [18, 47], \n'...
    '                            popupAnchor:  [-3, -50] }); \n\n']);

%% write RX positions to html file
for ii = 1:7
    if (ii ~= 6)
        fprintf(fid, ['  var marker_rx' num2str(ii) ' = L.marker([' num2str(rx_lat(ii), 8) ', ' num2str(rx_long(ii), 8) '], \n']);
        if (ii < 4)
            fprintf(fid, ['                            {title: \'' Receiver ' int2str(ii) ' \''}) \n']);     % label when user hovers over marker
        else
            switch ii
                case 4
                    fprintf(fid, '                            {title: \'' Target\'', icon: targetPointIcon}) \n');
                case 5
                    fprintf(fid, '                            {title: \'' Referensi\'', icon: targetPointIcon}) \n');
                case 6
                    fprintf(fid, '                            {title: \'' Center Point of Surabaya\''}) \n');
                case 7
                    fprintf(fid, '                            {title: \'' AVG\''}) \n');
            end
        end
        fprintf(fid, '                            .addTo(map) \n');

        if (ii < 4)
            fprintf(fid, ['                            .bindPopup(\''Receiver ' int2str(ii) ' \''); \n\n']); % label when user klicks on marker
        else
            switch ii
                case 4
                    fprintf(fid, ['                            .bindPopup(\''Target | ' num2str(rx_lat(ii), 8) ', ' num2str(rx_long(ii), 8) ' \''); \n\n']);
                case 5
                    fprintf(fid, ['                            .bindPopup(\''Referensi | ' num2str(rx_lat(ii), 8) ', ' num2str(rx_long(ii), 8) ' \''); \n\n']);
                case 6
                    fprintf(fid, ['                            .bindPopup(\''Center Point of Surabaya | ' num2str(rx_lat(ii), 8) ', ' num2str(rx_long(ii), 8) ' \''); \n\n']);
                case 7
                    % distance_hasil = dist_latlong(rx_lat(ii), rx_long(ii), rx_lat(8), rx_long(8), rx_lat(8), rx_long(8));
                    % distance_target = dist_latlong(rx_lat(4), rx_long(4), rx_lat(8), rx_long(8), rx_lat(8), rx_long(8));
                    % akurasi = 100 - ((abs(distance_target - distance_hasil) / distance_target) * 100);
                    akurasi = 100 * (1-(dist_latlong(rx_lat(4), rx_long(4), rx_lat(ii), rx_long(ii), rx_lat(6), rx_long(6)) / dist_latlong( rx_lat(8), rx_long(8), rx_lat(4), rx_long(4), rx_lat(6), rx_long(6))));
                    
                    disp(['akurasi hyperbola => ', num2str(akurasi), '%']);
                    fprintf(fid, ['                            .bindPopup(\''AVG | ' num2str(rx_lat(ii), 8) ', ' num2str(rx_long(ii), 8) ' | ' num2str(akurasi, 3) ' \''); \n\n']);
            end
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generate Hyperbola Line %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write hyperbolas
%%%%%%%% fill arrays with data points
for ii_hyperb = 1:num_hyperbolas
    %         disp("hyperbola ______________________________________________________________________________________________");
    hyperbola_lat_vector  = cell2mat(hyperbola_lat(ii_hyperb));
    hyperbola_long_vector = cell2mat(hyperbola_long(ii_hyperb));
    
    fprintf(fid, ['  var polyline_hyperbola_' int2str(ii_hyperb) ' = L.polyline([\n']);
    
    for ii_point = 1:num_hyperb_points(ii_hyperb)
        % disp(num2str(ii_hyperb));
        % disp(num2str(hyperbola_lat_vector(ii_point),8));
        % disp(num2str(hyperbola_long_vector(ii_point),8));
        fprintf(fid, ['                             [' num2str(hyperbola_lat_vector(ii_point),8) ', ' num2str(hyperbola_long_vector(ii_point),8) '], \n']);
    end
    
    fprintf(fid, ['	                         ], \n' ...
        '	                         { color: \''blue\'', weight: 1, opacity: 0.5} \n' ...
        '                          ).addTo(map);\n\n']);
end
fprintf(fid, '\n');

% for ii_hyperb = 1:num_hyperbolas
%     hyperbola_lat_vector  = cell2mat(hyperbola_lat(ii_hyperb));
%     hyperbola_long_vector = cell2mat(hyperbola_long(ii_hyperb));

%     for ii_point = 1:num_hyperb_points(ii_hyperb)
%         fprintf(fid, ['  var marker_hyperbola_' int2str(ii_hyperb) '_' int2str(ii_point) ' = L.marker([' num2str(hyperbola_lat_vector(ii_point),8) ', ' num2str(hyperbola_long_vector(ii_point),8) '], {title: \'' Receiver \''}).addTo(map); \n\n']);
%     end
% end


%% add heatmap

%  extract data
heat_long  = heatmap_cell{1};
heat_lat  = heatmap_cell{2};
heat_mag  = heatmap_cell{3};

% Add by Siswo
% Scope area of heatmap
start_lat = heatmap_cell{4};
stop_lat = heatmap_cell{5};
start_long = heatmap_cell{6};
stop_long = heatmap_cell{7};

if ((length(heat_long) ~= length(heat_lat)) || (length(heat_long) ~= length(heat_mag)))
    error('create_html_file.m: Length of heatmap vectors in cell array do not match');
end

heat_num_points = length(heat_long);

max_heat_mag = 0;
max_heat_mag_lat = 0;
max_heat_mag_long = 0;

d_max = 0;
d_target = 0;
akurasi = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generate Heatmap %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(fid, '\n  var heatmapData = L.heatLayer([\n');
for ii_lat = 1:heat_num_points
    for ii_long = 1:heat_num_points
        if (max_heat_mag < heat_mag(ii_long, ii_lat))
            max_heat_mag = heat_mag(ii_long, ii_lat);
            max_heat_mag_lat = heat_lat(ii_lat);
            max_heat_mag_long = heat_long(ii_long);
        end
        if (heat_mag(ii_long, ii_lat) > heatmap_threshold) || ((ii_lat == heat_num_points) && (ii_long == heat_num_points))
            if (heat_mag(ii_long, ii_lat) >= 0.99999)
                % disp(["heat => ", heat_mag(ii_long, ii_lat)]);
                % [x_hasil, y_hasil] = latlong2xy(heat_lat(ii_lat), heat_long(ii_long), rx_lat(6), rx_long(6));
                % [x_target, y_target] = latlong2xy(rx_lat(4), rx_long(4), rx_lat(6), rx_long(6));
                % disp(['x_hasil => ', num2str(x_hasil)]);
                % disp(['y_hasil => ', num2str(y_hasil)]);
                % disp(['x_target => ', num2str(x_target)]);
                % disp(['y_target => ', num2str(y_target)]);
                
                % distance_hasil = 1000 * sqrt( (x_hasil * x_hasil) + (y_hasil * y_hasil));
                % distance_hasil = dist_latlong(heat_lat(ii_lat), heat_long(ii_long), rx_lat(8), rx_long(8), rx_lat(6), rx_long(6));
                % distance_target = 1000 * sqrt( (x_target * x_target) + (y_target * y_target));
                % distance_target = dist_latlong(rx_lat(4), rx_long(4), rx_lat(8), rx_long(8), rx_lat(6), rx_long(6));
                % disp(['dist_hasil > ', num2str(distance_hasil)]);
                % disp(['dist_target > ', num2str(distance_target)]);
                
                % akurasi = 100 - ((abs(distance_target - distance_hasil) / distance_target) * 100);
                % akurasi = 100 * (1-(dist_latlong(tx_target_lat, tx_target_long, lat_calc, long_calc, geo_ref_lat, geo_ref_long) / dist_latlong( rx_lat(8), centerarea_long, tx_target_lat, tx_target_long, geo_ref_lat, geo_ref_long)));
                akurasi = 100 * (1-(dist_latlong(rx_lat(4), rx_long(4), heat_lat(ii_lat), heat_long(ii_long), rx_lat(6), rx_long(6)) / dist_latlong( rx_lat(8), rx_long(8), rx_lat(4), rx_long(4), rx_lat(6), rx_long(6))));
                disp(['akurasi heatmap => ', num2str(akurasi), '%']);
            end
            fprintf(fid, ['    [' num2str(heat_lat(ii_lat), 8) ', ' num2str(heat_long(ii_long), 8) ', ' num2str(heat_mag(ii_long, ii_lat)) ']']) ;
            
            if (ii_lat == heat_num_points) && (ii_long == heat_num_points)
                fprintf(fid, '\n  ]).addTo(map);\n');
            else
                fprintf(fid, ',\n');
            end
        end
        
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Rectangle Area Heatmap %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fprintf(fid, ['  var latlongAreaHeatmap = [\n'...
%     '                           [' num2str(start_lat, 8) ', ' num2str(start_long, 8) '],\n'...
%     '                           [' num2str(start_lat, 8) ', ' num2str(stop_long, 8) '],\n'...
%     '                           [' num2str(stop_lat, 8) ', ' num2str(stop_long, 8) '],\n'...
%     '                           [' num2str(stop_lat, 8) ', ' num2str(start_long, 8) '],\n'...
%     '  ];\n']);
% fprintf(fid, ['  var areaHeatmap = L.polygon(latlongAreaHeatmap, {color: \'' #333333\''}).addTo(map);\n']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Max Heat Point %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(fid, ['  var maxHeatPoint = L.marker([' num2str(max_heat_mag_lat, 8) ', ' num2str(max_heat_mag_long, 8) '], \n'...
    '                            {title: \'' Max Heat Point \'', icon: hasilPointIcon}) \n'...
    '                            .addTo(map) \n']);
fprintf(fid, ['                            .bindPopup(\'' Max Heat | ' num2str(max_heat_mag_lat, 8) ', ' num2str(max_heat_mag_long, 8) ' | ' num2str(akurasi, 3) ' \''); \n\n']);


%% footer

fprintf(fid, [...
    '\n'...
    '</script>\n'...
    '</body>\n'...
    '</html>\n'...
    '\n'...
    ]);

fclose(fid);

disp('writing html, done!');
end

