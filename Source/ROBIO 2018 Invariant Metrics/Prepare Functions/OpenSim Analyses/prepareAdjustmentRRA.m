function prepareAdjustmentRRA(...
    root, subject, foot, context, assistance)
% This function obtains the necessary paths to run an adjustment RRA.
% It assumes a filestructure used for the ROBIO 2017 submission. For
% adjustment RRA, we just take the first grf/ik file corresponding to the
% data path defined by hte inputs, and run adjustmentRRA on this.
%
% This is designed to be passed as a function handle to the processData 
% function. 

grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
grf_files = dir([constructDataPath(...
    root, subject, foot, context, assistance) '\*.mot']);
first_grf = [grf_path '\' grf_files(1).name];
ik_path = [grf_path '\IK_Results'];
ik_files = dir([ik_path '\*.mot']);
first_ik = [ik_path '\' ik_files(1).name];
model_path = constructModelPath(root, subject, assistance);
output_dir = [grf_path '\RRA_Results'];

% Run adjustment RRA.
[~, path] = adjustmentRRA(model_path, first_ik, first_grf, output_dir);

% Copy adjusted model file in to appropriate location.
[~, model_name, ~] = fileparts(model_path);
[~, new_model_name, ext] = fileparts(path);
copyfile(path, [root filesep 'S' num2str(subject) filesep 'Scaling' filesep model_name '_' new_model_name ext]);

end