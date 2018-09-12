function runBatch(...
    analyses, model, motion_folder, results_folder, grf_folder, varargin)

    % If the desired results folder doesn't exist, create it.
    if ~exist(rel2abs(results_folder), 'dir')
        mkdir(rel2abs(results_folder));
    end
    
    % Obtain the files in the motion and grf folders.
    motions = dirNoDots(rel2abs(motion_folder));
    grfs = dirNoDots(rel2abs(grf_folder));
    
    % Check you have the same number of files.
    if length(motions) ~= length(grfs) 
        error('Unmatched number of motion/grf files.');
    end
    
    % Iterate over the files.
    for i=1:length(motions)
        % Create an OpenSimTrial.
        trial = OpenSimTrial(model, ...
            [motion_folder filesep motions(i,1).name], ...
            [results_folder filesep num2str(i)], ...
            [grf_folder filesep grfs(i,1).name]);
        
        % Perform each analysis in turn.
        for j=1:length(analyses)
            trial.run(analyses{j}, varargin{:});
        end
    end

end