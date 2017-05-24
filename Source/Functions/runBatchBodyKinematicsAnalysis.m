function [Positions_array, Velocities_array, Accelerations_array] = ...
    runBatchBodyKinematicsAnalysis(model, input_folder, results_folder)
% Runs a batch of BodyKinematics analyses on a folder containing IK data. 

% If the desired results directory exists already, get its full path. If
% not, create it and get its full path. 
if exist([pwd '/' results_folder], 'dir')
    results_folder = getFullPath(results_folder);
else
    results_folder = createUniqueDirectory(results_folder);
end

% Obtain the files in the input folder.
ik_struct = dir([input_folder '/*.mot']);

% Create a cell array to hold the results.
n_files = size(ik_struct,1);
Positions_array{n_files} = {};
Velocities_array{n_files} = {};
Accelerations_array{n_files} = {};

% Iterate over the input files doing IK on each one and storing the results
% appropriately. 
for i=1:n_files
    [Positions_array{i}, Velocities_array{i}, Accelerations_array{i}] = ...
        runBodyKinematicsAnalysis(model, ...
        [input_folder '\' ik_struct(i,1).name], ...
        [results_folder '\' num2str(i)]);
end

end

