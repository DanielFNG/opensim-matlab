function result = prepareBatchRRA(...
    root, subject, foot, context, assistance, result)
% This function obtains the necessary paths to run a batch of RRA analyses.
% It assumes a filestructure used for the ROBIO 2017 submission. It assumes
% that adjustmentRRA's have already been done for this subject so that the
% adjusted model files can be accessed.
%
% This is designed to be passed as a function handle to the processData
% function.

% Get appropriate paths.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
ik_path = [grf_path '\IK_Results'];
model_path = constructAdjustedModelPath(root, subject, assistance);
output_dir = [grf_path '\RRA_Results'];

% Set load.
if assistance == 3
    load = 'apo_torques';
else
    load = 'normal';
end

% Run RRA batch, saving result if necessary.
if nargout == 1
    result.RRA{foot, context, assistance} = ...
        runBatchRRA(model_path, ik_path, grf_path, output_dir, load);
else
    runBatchRRA(model_path, ik_path, grf_path, output_dir, load);
end

end