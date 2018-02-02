function prepareBatchIK(root, subject, foot, context, assistance)
% This function obtains the necessary paths to run a batch of IK analyses.
% It assumes a filestructure used for the ROBIO 2017 submission.
%
% This is designed to be passed as a function handle to the processData
% function. 

data_path = ...
    constructDataPath(root, subject, foot, context, assistance);
model_path = constructModelPath(root, subject, assistance);
output_dir = [data_path '\IK_Results'];

runBatchIK(model_path, data_path, output_dir);

end