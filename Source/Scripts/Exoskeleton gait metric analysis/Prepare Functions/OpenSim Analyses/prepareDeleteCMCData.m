function prepareDeleteCMCData(root, subject, foot, context, assistance)

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);

% Remove the CMC folder. 
status = rmdir([grf_path filesep 'CMC_Results'], 's');

% Check that it worked. 
if status ~= 1
        %error('Unable to delete CMC folder.')
end



