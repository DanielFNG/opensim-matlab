function result = prepareAdjustmentRRA(...
    root, subject, foot, context, assistance, result)
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
result.MassAdjustment = adjustmentRRA(model_path, first_ik, first_grf, ...
    output_dir);

end