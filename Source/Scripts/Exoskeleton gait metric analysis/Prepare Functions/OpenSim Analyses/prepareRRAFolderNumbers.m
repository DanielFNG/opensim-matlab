function prepareRRAFolderNumbers(root, subject, foot, context, assistance)

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
rra_path = [grf_path filesep 'RRA_Results'];

% Identify the folders in the correct path, removing the adjustment RRA
% folder if it exists.
all_folders = getSubfolders(rra_path);
non_adjustment = ~strcmp({all_folders.name},'adjustment');
folders = all_folders(non_adjustment);

% Read in the RRA analyses appropriately. 
for i=1:vectorSize(folders)
    % Identify the RRA folder.
    folder = getSubfolders([rra_path filesep folders(i,1).name]);
    if length(folder) ~= 1
        fprintf('%i RRA folders for subject %i foot %i assistance %i context %i.\n', vectorSize(folder), subject, foot, assistance, context);
    end
end