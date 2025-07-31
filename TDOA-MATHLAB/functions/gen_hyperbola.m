function [ points_lat, points_long ] = gen_hyperbola( doa_meters, rx1_lat, rx1_long, rx2_lat, rx2_long, geo_ref_lat, geo_ref_long, rx1_name, rx2_name)
%gen_hyperbola: calculates the points of a hyperbola from receiver positions
%               and the doa in meters
  
    
    % convert to xy coordinates
    [rx1_x, rx1_y] = latlong2xy(rx1_lat, rx1_long, geo_ref_lat, geo_ref_long);
    [rx2_x, rx2_y] = latlong2xy(rx2_lat, rx2_long, geo_ref_lat, geo_ref_long);


    % mit Kosinussatz Dreieck berechnen | menghitung dengan aturan kosinus segitiga
    rx_x_dist = rx2_x - rx1_x;
    rx_y_dist = rx2_y - rx1_y;

    rx_dist_complex = rx_x_dist + i*rx_y_dist;
    dist_12 = abs (rx_dist_complex);  % positions in complex plane
    angle_12 = angle (rx_dist_complex); % -pi to +pi
    disp(['rx_dist_complex: ', num2str(rx_dist_complex)]);
    disp(['Distance between RX1(' num2str(rx1_lat) ', ' num2str(rx1_long) ') and RX2(' num2str(rx2_lat) ', ' num2str(rx2_long) '): ' num2str(dist_12) ' km, angle: ' num2str(angle_12) ' rad']);

    hyp_x = zeros(1,1);
    hyp_y = zeros(1,1);

    hyp_x_leg1 = zeros(1,1);
    hyp_y_leg1 = zeros(1,1);
    hyp_x_leg2 = zeros(1,1);
    hyp_y_leg2 = zeros(1,1);
    hyp_point_counter = 0;
    
    if abs(doa_meters/1000) > dist_12
        disp(['<strong>TODA delay (' num2str(doa_meters) ' meters) larger than RX distance (' num2str(1000*  dist_12) ' meters) -> no solution possible </strong>']);
        doa_meters = sign(doa_meters) * 0.995 * dist_12 * 1000;
        disp(['<strong>ATTENTION: Correcting TODA delay to 0.995 * RX distance (maximum possible value) = ' num2str(0.995*doa_meters) '</strong>']);
    end
        
        
    if abs(doa_meters/1000) <= dist_12

        %for r_1 = (exp(0:0.05:4)-1) / 5
        for r_1 = 0:0.05:10
            r_2 = r_1 - doa_meters/1000;
            %disp(['r_1 = ' num2str(r_1) ', r_2 = ' num2str(r_2)]);

            if ((r_2 + r_1) > dist_12)  % checks if triangle can be created || berdasarkan teorema pertidaksamaan segitiga
                
				acos_argument = (r_2^2 - r_1^2 - dist_12^2) / (-2*r_1*dist_12); % cosine theorem || cos(C) = (a^2 + b^2 - c^2) / (2ab)
				
				if (acos_argument >= -1) && (acos_argument <= +1) % checks if triangle can be created
				
					hyp_point_counter = hyp_point_counter + 1;

					hyp_angle = acos(acos_argument); % inner angle of triangle at RX1
                
					abs_angle1 = wrap2pi(angle_12 + hyp_angle);  % 1st solution: hyperbola leg 1
					hyp_x_leg1(hyp_point_counter) = rx1_x + r_1 * cos(abs_angle1);
					hyp_y_leg1(hyp_point_counter) = rx1_y + r_1 * sin(abs_angle1);

					abs_angle2 = wrap2pi(angle_12 - hyp_angle);  % 2nd solution: hyperbola leg 2 
					hyp_x_leg2(hyp_point_counter) = rx1_x + r_1 * cos(abs_angle2);
					hyp_y_leg2(hyp_point_counter) = rx1_y + r_1 * sin(abs_angle2);
                else
                    %disp(['acos argument ' num2str(acos_argument)]);
				end
            end

        end
    else
        disp('TODA delay larger than RX distance -> no solution possible');
    end
    
    if (hyp_point_counter == 0)
        disp('Hyperbola could not be constructed');
    end

    hyp_x = [fliplr(hyp_x_leg1) hyp_x_leg2];
    hyp_y = [fliplr(hyp_y_leg1) hyp_y_leg2];
    hyp_points = 2 * hyp_point_counter; % dikalikan 2 karena ada 2 sudut abs_angle1 dan abs_angle2
    
    
    points_lat = zeros(hyp_points,1);
    points_long = zeros(hyp_points,1);
    
    for ii=1:1:hyp_points
        [points_lat(ii), points_long(ii)] = xy2latlong(hyp_x(ii), hyp_y(ii), geo_ref_lat, geo_ref_long);
    end

    % Menghitung titik-titik pada hiperbola
    points_lat = zeros(hyp_points,1);
    points_long = zeros(hyp_points,1);

    for ii=1:1:hyp_points
        [points_lat(ii), points_long(ii)] = xy2latlong(hyp_x(ii), hyp_y(ii), geo_ref_lat, geo_ref_long);
    end

    % % Membuat plot
    % figure;
    % hold on;

    % % Plot hiperbola
    % % plot(points_long, points_lat, 'b.', 'MarkerSize', 3);

    % % Plot kaki pertama hiperbola
    % plot(hyp_x_leg1, hyp_y_leg1, 'r.', 'MarkerSize', 3);

    % % Plot kaki kedua hiperbola
    % plot(hyp_x_leg2, hyp_y_leg2, 'g.', 'MarkerSize', 3);

    % % Menambahkan titik RX1 dan RX2
    % plot(rx1_x, rx1_y, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    % plot(rx2_x, rx2_y, 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');

    % % Menambahkan garis dari RX1 ke RX2
    % plot([rx1_x, rx2_x], [rx1_y, rx2_y], 'b-', 'LineWidth', 1.5);

    % % Menambahkan label dan judul
    % xlabel('x-axis');
    % ylabel('y-axis');
    % title(['Hyperbola Plot with ' rx1_name ' and ' rx2_name]);
    % legend('Positif Angle', 'Negatif Angle', rx1_name, rx2_name, ['Line ' rx1_name ' to ' rx2_name]);

    % % Menampilkan grid
    % grid on;

    % hold off;

    disp(['Hyperbola with totally ' num2str(hyp_points) ' points generated.']);
end

