function result = prepareIDFromFile(...
    root, subject, foot, context, assistance, result)
% This function obtains the necessary paths to read in ID files and store
% them as data objects.
%
% This is designed to be passed as a function handle to the dataLoop
% function.

% Define some strings.
p1 = 'id.sto';

% Get appropriate path. 
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
id_path = [grf_path filesep 'ID_Results' filesep];

% Identify the folders in the correct path.
folders = getSubfolders(id_path);

% Create a cell array of the appropriate size;
id{vectorSize(folders)} = {};

% Read in the ID analyses appropriately.
for i=1:vectorSize(folders)
    % Identify the ID folder.
    folder = getSubfolders([id_path folders(i,1).name]);
    if vectorSize(folder) ~= 1
        fprintf('Subject %i, foot %i, context %i, assistance $i.', ...
            subject, foot, context, assistance);
        error('Multiple ID folders detected.')
    end

    % Load.
    id{i} = Data(...
        [id_path folders(i,1).name filesep folder(1,1).name filesep p1]);
end

result.ID{foot, context, assistance} = id;


