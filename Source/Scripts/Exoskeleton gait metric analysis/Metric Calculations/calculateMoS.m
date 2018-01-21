function result = calculateMoS(markers, positions, velocities, grfs, ...
    label, com_label, grf_label, walking_speed, leg_length, mode, foot)

    % Gravity constant and number of points to normalise data to.
    gravity = 9.80665;
    n_points = 1001;
    
    % Isolate and normalise data. 
    pos = stretchVector(markers. ...
        getDataCorrespondingToLabel(label), n_points);
    com_pos = stretchVector(positions. ...
        getDataCorrespondingToLabel(com_label), n_points);
    com_vel = stretchVector(velocities. ...
        getDataCorrespondingToLabel(com_label), n_points);
    grfs_y = stretchVector(grfs. ...
        getDataCorrespondingToLabel(grf_label), n_points);
    
    % Isolate the stance phase. 
    stance = find(grfs_y > 10);

    % The calculation is different depending on direction. 
    if strcmp(mode, 'AP')
        % If looking at AP direction, account for relative motion of the
        % treadmill.
        corrected_com_x = accountForTreadmill(...
            com_pos, markers.Frequency, walking_speed);
        corrected_com_vx = com_vel + walking_speed;
        
        % Calculate MoSAP.
        com_ap = corrected_com_x + ...
            corrected_com_vx*sqrt(leg_length/gravity);
        result = min(com_ap(stance) - pos(stance))*-1;
    elseif strcmp(mode, 'ML')
        % Calculate MoSML
        com_ml = com_pos + com_vel*sqrt(leg_length/gravity);
        switch foot
            case 1
                result = min(pos(stance) - com_ml(stance));
            case 2
                result = max(pos(stance) - com_ml(stance))*-1;
        end
    end

end