function path = constructAdjustedModelPath(root, subject, assistance)
% This function returns the path to the subject specific model used during
% the ROBIO 2017 submission, after RRA adjustment. It makes assumptions 
% about the folder structure described by the definitions of first and 
% third. It also assumes that the adjustment RRA's are done during 
% context 2 - which is indeed the case. 

model_path = constructModelPath(root, subject, assistance);
[~, model_name, ~] = fileparts(model_path);

path = [root '\S' num2str(subject) '\Scaling\' model_name '_' 'model_adjusted_mass_changed.osim'];

end