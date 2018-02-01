function result = prepareCMCFromFile(...
    root, subject, foot, context, assistance, result)

% Define some strings.
p1 = 'CMC_Results';

% Get appropriate paths.
model_path = constructAdjustedModelPath(root, subject, assistance);
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
rra_path = [grf_path filesep 'RRA_Results'];
cmc_path = [grf_path filesep p1 filesep];

% Obtain the files in the RRA and GRF folders.
rra_struct = dir([rra_path filesep '*.sto']);
grf_struct = dir([grf_path filesep '*.mot']);

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
    
    % Construct the OpenSimTrial.
    Trial = OpenSimTrial(model_path, ...
        [rra_path filesep rra_struct(i,1).name], 'normal', ...
        [grf_path filesep grf_struct(i,1).name], 'NotNeeded');
    
    % Load
    cmc{i} = CMCResults(Trial, ...
        [cmc_path all_folders(i,1).name filesep folder(1,1).name filesep 'CMC']);
end

result.CMC{foot, context, assistance} = cmc;

end