function result = prepareCMCFromFile(...
    root, subject, foot, context, assistance, result)

% Define some strings.
p1 = 'CMC_Results';

% Get appropriate paths.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
cmc_path = [grf_path filesep p1 filesep];

% Identify the folders in the correct path.
all_folders = getSubfolders(cmc_path);

% Create a cell array of the appropriate size.
cmc{vectorSize(all_folders)} = {};

% Read in the CMC analyses appropriately.
for i=1:vectorSize(all_folders)
    % Identify the CMC folder.
    folder = getSubfolders([cmc_path all_folders(i,1).name]);
    if vectorSize(folder) ~= 1
        fprintf('Subject %i, foot %i, context %i, assistance $i.', ...
            subject, foot, context, assistance);
        error('Multiple CMC folders detected.')
    end
    
    % Load
    cmc{i} = CMCResults([cmc_path all_folders(i,1).name filesep ...
        folder(1,1).name filesep 'CMC']);
end

result.CMC{foot, context, assistance} = cmc;

end