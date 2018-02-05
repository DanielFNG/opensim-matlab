function prepareDeleteOldForceData(...
    root, subject, foot, context, assistance)

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
rra_path = [grf_path filesep 'RRA_Results'];

% Remove the wrong things.
folders = getSubfolders(rra_path);
for i=1:length(folders)
    folder = getSubfolders([rra_path filesep folders(i).name]); 
    status = rmdir([rra_path filesep folders(i).name filesep folder(2).name], 's');

    % Check that it worked.
    if status ~= 1
            fprintf('Subject %i, foot %i, context %i, assistance $i.', ...
                subject, foot, context, assistance);
            error('Unable to delete ID folder.')
    end
end