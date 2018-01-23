function result = prepareBatchCMC(...
    root, subject, foot, context, assistance, result)

% Get appropriate paths.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
kinematics_data_path = [grf_path '\RRA_Results'];
model_path = constructAdjustedModelPath(root, subject, assistance);
output_dir = [grf_path '\CMC_Results'];

% Run CMC batch.
result.CMC{foot, context, assistance} = ...
    runBatchCMC(model_path, kinematics_data_path, grf_path, output_dir);
