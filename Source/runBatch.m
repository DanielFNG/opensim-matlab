% Run a batch of OpenSim analyses. 
%
% - analyses: ordered cell array of OpenSim analyses
% - model: model file to be used 
% - motion_folder: folder containing motion data
% - results_folder: folder to which results are printed 
% - grf_folder: folder containing external forces
% - varargin: arguments to OpenSim analyses 
function runBatch(...
    analyses, model, motion_folder, results_folder, grf_folder, varargin)

    % If the desired results folder doesn't exist, create it.
    if ~exist(results_folder, 'dir')
        mkdir(results_folder);
    end
    
    % Obtain the files in the motion and grf folders.
    [n_motions, motions] = dirNoDots(motion_folder);
    [n_grfs, grfs] = dirNoDots(grf_folder);
    
    % Check you have the same number of files.
    if n_motions ~= n_grfs 
        error('Unmatched number of motion/grf files.');
    end
    
    if n_motions == 0
        error('Could not find files.');
    end
    
    % Iterate over the files.
    for i=1:n_motions
        % Create an OpenSimTrial.
        trial = OpenSimTrial(model, motions{i}, ...
            [results_folder filesep num2str(i)], grfs{i});
        
        % Perform each analysis in turn.
        for j=1:length(analyses)
            trial.run(analyses{j}, varargin{:});
        end
    end

end