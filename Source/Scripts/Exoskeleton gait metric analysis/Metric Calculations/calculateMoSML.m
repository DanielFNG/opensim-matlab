function result = calculateMoSML(subject_data, foot, context, assistance)

gravity = 9.80665;
n_points = 1001;
ankle_label = '_Ankle_LatZ';
com_label = 'center_of_mass_Z';
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
    ankle_pos = stretchVector(marker_data{i}. ...
        getDataCorrespondingToLabel([prefix ankle_label]),n_points);
    com_pos_z = stretchVector(body_positions{i}. ...
        getDataCorrespondingToLabel(com_label),n_points);
    com_vel_z = stretchVector(body_velocities{i}. ...
        getDataCorrespondingToLabel(com_label),n_points);
    grfs_y = stretchVector(grfs{i}. ...
        getDataCorrespondingToLabel(grf_label),n_points);
    
    % Convert marker data to metres.
    ankle_pos = ankle_pos/1000; 
    
    % Isolate the stance phase. 
    stance = isolateStancePhase(grfs_y, foot);
    
    % Calculate thing.
    com_ml = com_pos_z + com_vel_z*sqrt(subject_data.LegLength/gravity);

    switch foot
        case 1
            result{i} = min(ankle_pos(stance) - com_ml(stance));
        case 2
            result{i} = max(ankle_pos(stance) - com_ml(stance))*-1;
    end
end

end