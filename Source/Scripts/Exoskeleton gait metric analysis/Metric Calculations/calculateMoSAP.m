function result = calculateMoSAP(subject_data, foot, context, assistance)

gravity = 9.80665;
n_points = 1001;
heel_label = '_HeelX';
com_label = 'center_of_mass_X';
grf_label = ['    ground_force' num2str(foot) '_vy'];

switch foot
    case 1
        prefix = 'R';
    case 2
        prefix = 'L';
end

% Gain access to the appropriate cell arrays of data. 
marker_data = ...
    subject_data.IK{foot, context, assistance}.Input_Markers_array;
body_positions = ...
    subject_data.BodyKinematics{foot, context, assistance}.positions;
body_velocities = ...
    subject_data.BodyKinematics{foot, context, assistance}.velocities;
grfs = subject_data.GRF{foot, context, assistance};

% Create appropriately sized cell array. 
result{vectorSize(grfs)} = {};

% Loop over the cell arrays. 
for i=1:vectorSize(grfs)
    
    % Isolate the required data, at the same time normalising them to 1000
    % frames for the calculation.
    heel_pos = stretchVector(marker_data{i}. ...
        getDataCorrespondingToLabel([prefix heel_label]),n_points);
    com_pos_x = stretchVector(body_positions{i}. ...
        getDataCorrespondingToLabel(com_label),n_points);
    com_vel_x = stretchVector(body_velocities{i}. ...
        getDataCorrespondingToLabel(com_label),n_points);
    grfs_y = stretchVector(grfs{i}. ...
        getDataCorrespondingToLabel(grf_label),n_points);
    
    % Convert marker data to metres. 
    heel_pos = heel_pos/1000;
    
    % Isolate the stance phase. 
    stance = isolateStancePhase(grfs_y, foot);

    % Calculate treadmill-corrected com positions and speed.
    corrected_com_x = accountForTreadmill(...
        com_pos_x, marker_data.Frequency, subject_data.WalkingSpeed{context});
    corrected_com_vx = com_vel_x + subject_data.WalkingSpeed{context};
    
    % Calculate thing.
    com_ap = corrected_com_x + corrected_com_vx*sqrt(subject_data.LegLength/gravity);

    result{i} = min(com_ap(stance) - heel_pos(stance))*-1;
end

end