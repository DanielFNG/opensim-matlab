function results = runBatch(...
    analyses, model, motion_folder, results_folder, grf_folder, varargin)
% Run a batch of OpenSim analyses.
%
%   Input arguments:
%       - analyses: ordered cell array of OpenSim analyses to be run
%       - model: model file to be used
%       - motion_folder: folder containing only motion data
%       - results_folder: folder to which results are output
%       - grf_folder: folder containing external force files
%       - varargin: optional arguments to OpenSim analyses
%
%   Output arguments:
%       - results: optional, cell array containing OpenSimResults objects
    
    % Obtain the files in the motion and grf folders.
    [n_motions, motions] = dirNoDots(motion_folder);
    [n_grfs, grfs] = dirNoDots(grf_folder);
    
    % Check you have the same number of files.
    if n_motions ~= n_grfs 
        error('Unmatched number of motion/grf files.');
    end
    
    % Check that there are any files at all. 
    if n_motions == 0
        error('Could not find files.');
    end
    
    % If the desired results folder doesn't exist, create it.
    if ~exist(results_folder, 'dir')
        mkdir(results_folder);
    end
    
    % Iterate over the files.
    trials = cell(1, n_motions);
    for i=1:n_motions
    
        % Create an OpenSimTrial.
        trials{i} = OpenSimTrial(model, motions{i}, ...
            [results_folder filesep num2str(i)], grfs{i});
        
        % Perform analyses.
        trials{i}.run(analyses, varargin{:});
        
    end

    % Create OpenSimResults only if required.
    if nargout > 0
        analyses{end+1} = 'GRF';
        results = cell(1, n_motions);
        for i=1:n_motions
            results{i} = OpenSimResults(trials{i}, analyses);
        end
    end
    
end