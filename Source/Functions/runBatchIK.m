function [IK_array, Input_Markers_array, Output_Markers_array] = ...
    runBatchIK(model, input_folder, results_folder)
% Performs IK using default settings on given model and a batch of input
% data. Uses runIK function. 

% If the desired results directory exists already, get its full path. If
% not, create it and get its full path. 
if exist([pwd '/' results_folder], 'dir')
    results_folder = getFullPath(results_folder);
else
    results_folder = createUniqueDirectory(results_folder);
end

% Obtain the files in the input folder. 
trc_struct = dir([input_folder '/*.trc']);

% Create a cell array to hold the IK results. 
IK_array{size(trc_struct,1)} = {};
Output_Markers_array{size(trc_struct,1)} = {};
Input_Markers_array{size(trc_struct,1)} = {};

% Iterate over the input files doing IK on each one and storing the results
% appropriately. 
for i=1:size(trc_struct,1)
    [IK_array{i}, Input_Markers_array{i}, Output_Markers_array{i}] = ...
        runIK(model, [input_folder '\' trc_struct(i,1).name], ...
        results_folder, num2str(i));
end

end
