function result = prepareBatchCMC(...
    root, subject, foot, context, assistance, result)

% Get appropriate paths.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
kinematics_data_path = [grf_path '\RRA_Results'];
model_path = constructAdjustedModelPath(root, subject, assistance);
output_dir = [grf_path '\CMC_Results'];

% Setup load.
if assistance == 3
    load = 'apo_torques';
else
    load = 'normal';
end

% Run CMC batch, saving result if necessary.
if nargout == 1
    result.CMC{foot, context, assistance} = ...
        runBatchCMC(...
        model_path, kinematics_data_path, grf_path, output_dir, load);
else
    runBatchCMC(...
        model_path, kinematics_data_path, grf_path, output_dir, load);
end

end

