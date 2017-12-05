function result = prepareBatchBodyKinematicsAnalysis(...
    root, subject, foot, context, assistance, output_dir)
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

if nargin == 5
    output_dir = [data_path '\BodyKinematics_Results'];
elseif nargin ~= 6
    error(['Incorrect number of arguments to '...
        'prepareBatchBodyKinematicsAnalysis.']);
end

% Run BodyKinematics analysis batch.
[result.positions, result.velocities, result.accelerations] = ...
    runBatchBodyKinematicsAnalysis(...
    model_path, kinematics_folder, output_dir);