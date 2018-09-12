function runBatch(...
    model, motion_folder, grf_folder, results_folder, analyses, varargin)

    % Set inner folder name.
    inner_folder_name = 'Batch';

    % If the desired results folder doesn't exist, create it.
    if ~exist(results_folder, 'dir')
        mkdir(results_folder);
    end
    
    % Obtain the files in the motion and grf folders.
    motions = dirNoDots(motion_folder);
    grfs = dirNoDots(grf_folder);
    
    % Check you have the same number of files.
    if length(motions) ~= length(grfs) 
        error('Unmatched number of motion/grf files.');
    end
    
    % Iterate over the files.
    for i=1:length(motions)
        % Create an OpenSimTrial.
        trial = OpenSimTrial(model, ...
            [motion_folder filesep motions(i,1).name], ...
            [grf_folder filesep grfs(i,1).name], ...
            [results_folder filesep inner_folder_name num2str(i)]);
        
        % Perform each analysis in turn.
        for j=1:length(analyses)
            analyses{j}(trial, varargin);
        end
    end

end