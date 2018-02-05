function prepareAPOGRFs(root, subject, foot, context, assistance)
% This function obtained the necessary paths to read in GRF files and APO
% torques and create GRF files modified to include the APO actuation. 
%
% This is designed to be passed as a function handle to the processData
% function.

% Force an error if the assistance level is not equal to 3. 
if assistance ~= 3
    error('Do NOT replace the grf files for the NE or ET cases.');
end

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
ik_path = [grf_path filesep 'IK_Results'];

% Identify the grf files.
ik_struct = dir([ik_path filesep '*.mot']);
grf_struct = dir([grf_path filesep '*.mot']);

for i=1:vectorSize(grf_struct)
    % Load in the right hip flexion joint angle trajectory. 
    ik = Data([ik_path filesep ik_struct(i,1).name]);
    if subject == 8 && context == 8 && i == 4
        right_hip = ik.getDataCorrespondingToLabel('hip_flexion_r');
        right_hip = right_hip(1:round(length(right_hip)/2));
    else
        right_hip = ik.getDataCorrespondingToLabel('hip_flexion_r');
    end
   
    % Create a scaled copy of the APO joint torques and right hip angle
    % which are twice the length of the hip vector.
    APO = computeAPOTorques([root filesep 'APO Torques'], subject);
    apo_right_hip = stretchVector(APO.AvgH_RightJointAngle. ...
        (['Context' num2str(context)]), 2*vectorSize(right_hip));
    apo_right_torque = stretchVector(APO.AvgH_RightActualTorque. ...
        (['Context' num2str(context)]), 2*vectorSize(right_hip));
    apo_left_torque = stretchVector(APO.AvgH_LeftActualTorque. ...
        (['Context' num2str(context)]), 2*vectorSize(right_hip));
    % Use cross correlation to align the right hip human joint angle to the
    % apo right joint angle.
    [ac, lag] = xcorr(apo_right_hip, right_hip);
    [~, index] = max(ac);
    shift = lag(index);
    
%     % Temporary sanity check.
%     apo_right_hip = apo_right_hip(shift:vectorSize(right_hip)+shift-1);
%     figure;
%     plot(right_hip);
%     hold on;
%     plot(apo_right_hip);
    
    % Shift the apo torque signals so that they are time aligned.
    apo_right_torque = apo_right_torque(shift:vectorSize(right_hip)+shift);
    apo_left_torque = apo_left_torque(shift:vectorSize(right_hip)+shift);
    
    % Get the number of timesteps of the GRF file, and stretch the apo 
    % torque signals accordingly. 
    grf = Data([grf_path filesep grf_struct(i,1).name]);
    n_timesteps = grf.Frames;
    apo_right_torque = stretchVector(apo_right_torque, n_timesteps);
    apo_left_torque = stretchVector(apo_left_torque, n_timesteps);
    
    % Make the labels.
    labels = {'time',...
        'apo_force_vx','apo_force_vy','apo_force_vz',...
        'apo_force_px','apo_force_py','apo_force_pz',...
        'apo_torque_x','apo_torque_y','apo_torque_z',...
        '1_apo_force_vx','1_apo_force_vy','1_apo_force_vz',...
        '1_apo_force_px','1_apo_force_py','1_apo_force_pz',...
        '1_apo_torque_x','1_apo_torque_y','1_apo_torque_z',...
        'apo_group_force_vx','apo_group_force_vy','apo_group_force_vz',...
        'apo_group_force_px','apo_group_force_py','apo_group_force_pz',...
        'apo_group_torque_x','apo_group_torque_y','apo_group_torque_z',...
        '1_apo_group_force_vx','1_apo_group_force_vy','1_apo_group_force_vz',...
        '1_apo_group_force_px','1_apo_group_force_py','1_apo_group_force_pz',...
        '1_apo_group_torque_x','1_apo_group_torque_y','1_apo_group_torque_z'};
    
    % Form the values.
    values = zeros(n_timesteps,length(labels)-1);
    values(1:end,1) = grf.Timesteps;
    values(1:end,2:9) = 0;
    values(1:end,10) = apo_right_torque;
    values(1:end,11:18) = 0;
    values(1:end,19) = apo_left_torque;
    values(1:end,20:27) = 0;
    values(1:end,28) = -apo_right_torque;
    values(1:end,29:36) = 0;
    values(1:end,37) = -apo_left_torque;
    
    % Create an empty data object then assign these labels and
    % values.
    apo_data = Data();
    apo_data.Values = values;
    apo_data.Labels = labels;
    apo_data.Timesteps = grf.Timesteps;
    apo_data.isTimeSeries = true;
    apo_data.Frames = grf.Frames;
    apo_data.Header = grf.Header;
    apo_data.hasHeader = true;
    apo_data.isLabelled = true;
    apo_data = apo_data.updateHeader();
    
    % Write out the modified GRF file, for the moment this is just for
    % testing purposes. 
    new_grfs = grf + apo_data;
    new_grfs.writeToFile([grf_path filesep grf_struct(i,1).name],1,1);
    
end

end
    
    