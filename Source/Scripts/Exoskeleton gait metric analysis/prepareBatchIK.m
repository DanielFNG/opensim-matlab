function result = prepareBatchIK(...
    root, subject, foot, context, assistance, output_dir)
% This function obtains the necessary paths to run a batch of IK analyses.
% It assumes a filestructure used for the ROBIO 2017 submission.
%
% This is designed to be passed as a function handle to the processData
% function. 

data_path = ...
    constructDataPath(root, subject, foot, context, assistance);
model_path = constructModelPath(root, subject, assistance);

if nargin == 5
    output_dir = [data_path '\IK_Results'];
elseif nargin ~= 6
    error('Incorrect number of arguments to prepareBatchIK.');
end

[result.IK_array, result.Input_Markers_array, ...
    result.Output_Markers_array] = ...
    runBatchIK(model_path, data_path, output_dir);

end