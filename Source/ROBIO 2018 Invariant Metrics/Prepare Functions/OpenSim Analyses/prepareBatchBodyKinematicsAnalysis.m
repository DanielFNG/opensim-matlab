function result = prepareBatchBodyKinematicsAnalysis(...
    root, subject, foot, context, assistance, result)
% This function obtains the necessary paths to run a batch of
% BodyKinematics analyses. It assumes a filestructure used for the ROBIO
% 2017 submission. It is also assumed that RRA adjustment and RRA have been 
% done so that RRA adjusted model and RRA kinematics files can be accessed.
%
% This is designed to be passed as a function handle to the processData
% function.

data_path = constructDataPath(...
    root, subject, foot, context, assistance);
kinematics_folder = [data_path '\RRA_Results'];
model_path = constructAdjustedModelPath(root, subject, assistance);
output_dir = [data_path '\BodyKinematics_Results'];

% Run BodyKinematics analysis batch, save result if necessary.
if nargout == 1
    [result.BodyKinematics.positions{foot, context, assistance}, ...
        result.BodyKinematics.velocities{foot, context, assistance}, ...
        result.BodyKinematics.accelerations{foot, context, assistance}] ...
        = runBatchBodyKinematicsAnalysis(...
        model_path, kinematics_folder, output_dir);
else
    runBatchBodyKinematicsAnalysis(...
        model_path, kinematics_folder, output_dir);
end

end