function result = prepareMoS(~, ~, foot, context, assistance, result)

% Define appropriate labels. 
switch foot
    case 1
        prefix = 'R';
    case 2
        prefix = 'L';
end
ankle_label = [prefix '_Ankle_LatZ'];
heel_label = [prefix '_HeelX'];
com_label_x = 'center_of_mass_X';
com_label_z = 'center_of_mass_Z';
grf_label = ['    ground_force' num2str(foot) '_vy'];

% Gain access to the appropriate data. 
marker_data = ...
    result.IK.Input_Markers_array{foot, context, assistance};
body_positions = ...
    result.BodyKinematics.positions{foot, context, assistance};
body_velocities = ...
    result.BodyKinematics.velocities{foot, context, assistance};
grfs = result.GRF{foot, context, assistance};
walking_speed = result.Properties.WalkingSpeed(context);
leg_length = result.Properties.LegLength;

% Create cell arrays to hold temporary results.
temp_ap{vectorSize(grfs)} = {};
temp_ml{vectorSize(grfs)} = {};

% Calculate the metrics and store the results. 
for i=1:vectorSize(grfs)
    % Convert marker data to metres.
    marker_data{i}.Values = marker_data{i}.Values/1000;

    temp_ap{i} = calculateMoS(marker_data{i}, body_positions{i}, ...
        body_velocities{i}, grfs{i}, heel_label, com_label_x, grf_label,...
        walking_speed, leg_length, 'AP', foot);
    temp_ml{i} = calculateMoS(marker_data{i}, body_positions{i}, ...
        body_velocities{i}, grfs{i}, ankle_label, com_label_z, ...
        grf_label, walking_speed, leg_length, 'ML', foot);
end

% Store results properly.
result.MetricsData.MoSAP{foot, context, assistance} = temp_ap;
result.MetricsData.MoSML{foot, context, assistance} = temp_ml;

end
    


