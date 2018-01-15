function result = prepareBatchID(...
    root, subject, foot, context, assistance, result)
% This function obtains the necessary paths to run a batch of ID analyses.
% It assumes a filestructure used for the ROBIO 2017 submission. It is 
% also assumed that ID is done on RRA files, so the RRA adjusted model
% and kinematics files are used in this function.
%
% This is designed to be passed as a function handle to the processData
% function. 

grf_data_path = constructDataPath(...
    root, subject, foot, context, assistance);
kinematics_data_path = [grf_data_path '\RRA_Results'];
model_path = constructAdjustedModelPath(root, subject, assistance);
output_dir = [grf_data_path '\ID_Results'];

% Run ID batch.
result.ID{foot, context, assistance} = ...
    runBatchID(...
    model_path, kinematics_data_path, grf_data_path, output_dir);
end