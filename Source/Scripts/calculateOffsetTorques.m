%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This test script runs a CMC simulation taking in to account joint       %
% offsets. Subject 7 has the highest offsets so the data from that will   %
% be used to provide a 'worst case' outlook.                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Some parameters.
length_apo = 0.23;

% Run the offsets script to calculate the offsets. Isolate the offsets for
% subject 7 (for now).
offsets = calculateOffsets;
offsets = offsets.s7;

% Load in the original forces file and access the original APO torques.
forces = Data('EA21.mot');
right_apo_torque = forces.getDataCorrespondingToLabel('apo_torque_z');
left_apo_torque = forces.getDataCorrespondingToLabel('1_apo_torque_z');

% Load in the RRA-corrected kinematics and isolate the left and right hip
% flexion joint angles. Simultaneously convert to radians. 
kinematics = Data('RRA_q_1.sto');
right_hip_angle = ...
    deg2rad(kinematics.getDataCorrespondingToLabel('hip_flexion_r'));
left_hip_angle = ...
    deg2rad(kinematics.getDataCorrespondingToLabel('hip_flexion_l'));

% Since the RRA is at 1000Hz and the GRFs are at 600Hz, the RRA data will
% always have more frames. Stretch the APO torques to be on the same number 
% of frames.
right_apo_torque = stretchVector(right_apo_torque, kinematics.Frames);
left_apo_torque = stretchVector(left_apo_torque, kinematics.Frames);

% Perform the calculations.
[right_human_length, right_special_angle] = ...
    calculateHumanLengthSpecialAngle(...
    offsets.R_x, offsets.R_y, right_hip_angle, length_apo);
[left_human_length, left_special_angle] = ...
    calculateHumanLengthSpecialAngle(...
    offsets.L_x, offsets.L_y, left_hip_angle, length_apo);
[right_torque, right_force] = calculateModifiedTorque(...
    right_apo_torque, right_special_angle, length_apo, right_human_length);
[left_torque, left_force] = calculateModifiedTorque(...
    left_apo_torque, left_special_angle, length_apo, left_human_length);

% I'm going to need to go back to the drawing board, here. I'm getting
% problems which I believe are related to there case where the hip angle 
% becomes small enough that the 'exoskeleton angle' becomes 0 or negative. 


