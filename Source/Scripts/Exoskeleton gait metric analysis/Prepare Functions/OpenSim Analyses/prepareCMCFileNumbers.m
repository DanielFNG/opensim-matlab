function prepareCMCFileNumbers(root, subject, foot, context, assistance)

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
cmc_path = [grf_path filesep 'CMC_Results'];

% Get the 1-5 CMC folders. 
folders = getSubfolders(cmc_path);

% Check that it worked. 
for i=1:5
    folder = getSubfolders([cmc_path filesep folders(i).name]);
    files = dir([cmc_path filesep folders(i).name filesep ...
        folder(1).name filesep '*.sto']);
    if length(files) ~= 74
        fprintf(['CMC folder subject %i foot %i context %i assistance' ...
            '%i instance %i has %i .sto files.\n'], ...
            subject, foot, context, assistance, i, length(files));
    end
end
    