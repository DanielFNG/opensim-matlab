function prepareOffsetGRFs(root, subject, foot, context, assistance)

if assistance ~= 3
    error('Do NOT replace the grf files for non-assistance cases.');
end

% Calculate offsets for all subjects (this needs fixed).
offsets = calculateOffsets();

% For now hard code the offsets for S7 and APO length.
offsets.R_x = offsets.(['s' num2str(subject)]).R_x;
offsets.R_y = offsets.(['s' num2str(subject)]).R_y;
offsets.L_x = offsets.(['s' num2str(subject)]).L_x;
offsets.L_y = offsets.(['s' num2str(subject)]).L_y;
length_apo = 0.23;

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
ik_path = [grf_path filesep 'RRA_Results'];

% Identify the grf files.
ik_struct = dir([ik_path filesep '*.sto']);
grf_struct = dir([grf_path filesep '*.mot']);

for i=1:length(grf_struct)
    % Load in the RRA hip joint angles and the GRFs. 
    kinematics = Data([ik_path filesep ik_struct(i,1).name]);
    forces = Data([grf_path filesep grf_struct(i,1).name]);
    
    % Get what we need.
    right_apo_torque = forces.getDataCorrespondingToLabel('apo_torque_z');
    left_apo_torque = forces.getDataCorrespondingToLabel('1_apo_torque_z');
    right_hip_angle = ...
        deg2rad(kinematics.getDataCorrespondingToLabel('hip_flexion_r'));
    left_hip_angle = ...
        deg2rad(kinematics.getDataCorrespondingToLabel('hip_flexion_l'));
    
    % Since the RRA is at 1000Hz and the GRFs are at 600Hz, the RRA data 
    % will always have more frames. Stretch the APO torques to be on the 
    % same number of frames.
    right_apo_torque = stretchVector(right_apo_torque, kinematics.Frames);
    left_apo_torque = stretchVector(left_apo_torque, kinematics.Frames);
    
    % Perform the calculations.
    [right_human_length, right_special_angle] = ...
        calculateHumanLengthSpecialAngle(...
        offsets.R_x, offsets.R_y, right_hip_angle, length_apo);
    [left_human_length, left_special_angle] = ...
        calculateHumanLengthSpecialAngle(...
        offsets.L_x, offsets.L_y, left_hip_angle, length_apo);
    [right_torque, right_axial_force] = calculateModifiedTorque(...
        right_apo_torque, right_special_angle, length_apo, right_human_length);
    [left_torque, left_axial_force] = calculateModifiedTorque(...
        left_apo_torque, left_special_angle, length_apo, left_human_length);
    
    % Rescale the torques to the correct number of frames.
    right_apo_torque = stretchVector(right_apo_torque, forces.Frames);
    left_apo_torque = stretchVector(left_apo_torque, forces.Frames);
    right_axial_force = stretchVector(right_axial_force, forces.Frames);
    left_axial_force = stretchVector(left_axial_force, forces.Frames);
    right_torque = stretchVector(right_torque, forces.Frames);
    left_torque = stretchVector(left_torque, forces.Frames);
    right_human_length = stretchVector(right_human_length, forces.Frames);
    left_human_length = stretchVector(left_human_length, forces.Frames);
    
    % Reassign the values.
    forces.Values(1:end, 21) = right_axial_force;
    forces.Values(1:end, 24) = -right_human_length;
    forces.Values(1:end, 28) = right_torque;
    forces.Values(1:end, 30) = left_axial_force;
    forces.Values(1:end, 33) = -left_human_length;
    forces.Values(1:end, 37) = left_torque;
    forces.Values(1:end, 46) = -right_apo_torque; % Still apply the full 
    forces.Values(1:end, 55) = -left_apo_torque; % torque to the APO. 
    
    % Rewrite these grfs. 
    forces.writeToFile([grf_path filesep grf_struct(i,1).name], 1, 1);
end

end
    
    
    