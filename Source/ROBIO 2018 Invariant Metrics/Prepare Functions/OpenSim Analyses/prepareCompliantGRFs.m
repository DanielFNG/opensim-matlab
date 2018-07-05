function prepareCompliantGRFs(root, subject, foot, context, assistance)

% Parameters. 
absorbtion_rate = 0.55;
return_rate = 0.75;
smoothing_window = 21;

if assistance ~= 3
    error('Do NOT replace the grf files for non-assistance cases.');
end

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);

% Identify the grf files.
grf_struct = dir([grf_path filesep '*.mot']); 

for i=1:length(grf_struct)
    % Load in the GRFs.
    forces = Data([grf_path filesep grf_struct(i,1).name]);
    
    % Identify the left and right APO torques.
    original_right_torque = forces.Values(1:end, 28);
    original_left_torque = forces.Values(1:end, 37);
    
    % Use the APO torques to identify the loading and unloading zones. 
    [rl1, ru1, rl2, ru2, ro] = identifyLoadingZones(original_right_torque);
    [ll1, lu1, ll2, lu2, lo] = identifyLoadingZones(original_left_torque);
    
    % Apply the aborbtion rate to the loading and unloading zones. 
    right_torque = applyAbsorbtion(absorbtion_rate, ..., 
        original_right_torque, {rl1, rl2}, {ru1, ru2}, ro);
    left_torque = applyAbsorbtion(absorbtion_rate, ...
        original_left_torque, {ll1, ll2}, {lu1, lu2}, lo);
    
    % Apply the return rate to the unloading zones only. 
    right_torque = smooth(applyReturn(return_rate, absorbtion_rate, ...
        right_torque, {rl1, rl2}, {ru1, ru2}), smoothing_window);
    left_torque = smooth(applyReturn(return_rate, absorbtion_rate, ...
        left_torque, {ll1, ll2}, {lu1, lu2}), smoothing_window);
    
    % Calculate the multipliers to apply to the forces.
    right_multiplier = right_torque./original_right_torque;
    left_multiplier = left_torque./original_left_torque;
    
    % Identify the left and right APO forces.
    right_force = forces.Values(1:end, 21);
    left_force = forces.Values(1:end, 30);
    
    % Calculate the changes left and right APO forces.
    right_force = right_force.*right_multiplier;
    left_force = left_force.*left_multiplier;
    
    % Reassign the APO force file values.
    forces.Values(1:end, 21) = right_force;
    forces.Values(1:end, 28) = right_torque;
    forces.Values(1:end, 30) = left_force;
    forces.Values(1:end, 37) = left_torque;
    
    % Rewrite the grfs. 
    forces.writeToFile([grf_path filesep grf_struct(i,1).name], 1, 1);
end

end
    
    
    
    