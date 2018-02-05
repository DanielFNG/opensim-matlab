function result = prepareRRAFromFile(...
    root, subject, foot, context, assistance, result)
% This function obtained the necessary paths to read in RRA results and
% store them as the appropriate objects.
%
% This is designed to be passed as a function handle to the dataLoop
% function.

% Define some strings.
p1 = 'RRA_Results';

% Get appropriate paths.
model_path = constructAdjustedModelPath(root, subject, assistance);
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
ik_path = [grf_path filesep 'IK_Results'];
rra_path = [grf_path filesep p1 filesep];

% Obtain the files in the IK and GRF folders.
ik_struct = dir([ik_path filesep '*.mot']);
grf_struct = dir([grf_path filesep '*.mot']);

% Identify the folders in the correct path, removing the adjustment RRA
% folder if it exists.
all_folders = getSubfolders(rra_path);
non_adjustment = ~strcmp({all_folders.name},'adjustment');
folders = all_folders(non_adjustment);

% Create a cell array of the appropriate size.
rra{vectorSize(folders)} = {};

% Read in the RRA analyses appropriately. 
for i=1:vectorSize(folders)
    % Identify the RRA folder.
    folder = getSubfolders([rra_path folders(i,1).name]);
    if vectorSize(folder) ~= 1
        error('Multiple RRA folders detected.')
    end
    
    % Construct the OpenSimTrial.
    Trial = OpenSimTrial(model_path, ...
        [ik_path filesep ik_struct(i,1).name], 'normal', ...
        [grf_path filesep grf_struct(i,1).name], 'NotNeeded');
    
    % Load
    rra{i} = RRAResults(Trial, ...
        [rra_path folders(i,1).name filesep folder(1,1).name filesep 'RRA']);
end

result.RRA{foot, context, assistance} = rra;
