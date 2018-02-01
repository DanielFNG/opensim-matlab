function result = deleteCMCData(...
    root, subject, foot, context, assistance, result)

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);

% Remove the CMC folder. 
status = rmdir([grf_path filesep 'CMC_Results'], 's');

% Check that it worked. 
if status ~= 1
        fprintf('Subject %s, foot %s, context %s, assistance $s.', ...
            subject, foot, context, assistance);
        error('Unable to delete CMC folder.')
end



