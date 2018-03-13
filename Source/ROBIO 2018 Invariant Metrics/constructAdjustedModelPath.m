function path = constructAdjustedModelPath(root, subject, assistance)
% This function returns the path to the subject specific model used during
% the ROBIO 2017 submission, after RRA adjustment. It makes assumptions 
% about the folder structure described by the definitions of first and 
% third. It also assumes that the adjustment RRA's are done during 
% context 2 - which is indeed the case. 

% The default model name after RRA adjustment. 
default_adjusted_model = '\model_adjusted_mass_changed.osim';

% The beginning of the default RRA folder name, used for identification.
default_RRA_folder = '\RRA_load';

% Assumptions about data folder structure. 
first = [root '\S' num2str(subject) '\dynamicElaborations\rightStSt\'];
third = '\RRA_Results\adjustment';

% Slight variation depending on human model vs human-APO model. 
if assistance == 1
    second = 'NE2';
else
    second = 'ET2';
end

% Get the path. 
adjustment_rra_folder = dir([first second third default_RRA_folder '*']);
if size(adjustment_rra_folder,1) == 1
    path = [first second third '\' ...
        adjustment_rra_folder.name default_adjusted_model];
elseif size(adjustment_rra_folder,1) == 0
    error('Could not find RRA adjusted model file.');
else 
    error('More than one adjustment RRA folder present.');
end

end