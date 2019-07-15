function trials = createTrials(model, motion_folder, results_folder, grf_folder)
% Create a batch of OpenSimTrial objects.
%
%   Input arguments:
%       - model: model file to be used
%       - motion_folder: folder containing only motion data
%       - results_folder: folder to which results are output
%       - grf_folder: folder containing external force files

    % Obtain the paths to files in the motion & grf folders.
    if isempty(motion_folder)
        n_motions = 0;
    else
        [n_motions, motions] = dirNoDots(motion_folder);
    end
    
    if isempty(grf_folder)
        n_grfs = 0;
    else
        [n_grfs, grfs] = dirNoDots(grf_folder);
    end
    
    % Check that there are any files at all.
    if n_motions == 0 && n_grfs == 0
        error('Could not find files.');
    end
    
    % Check that if there are both motion and grf files, then there are the
    % same number of each.
    if n_motions ~= n_grfs && (n_grfs ~= 0 && n_motions ~= 0)
        error('Unmatched number of motion/grf files.');
    end
    
    % If the desired results folder doesn't exist, create it.
    if ~exist(results_folder, 'dir')
        mkdir(results_folder);
    end
    
    % Iterate over the files.
    n = max(n_motions, n_grfs);
    trials = cell(1, n);
    for i=1:n
        % Create an OpenSimTrial
        if n_motions == 0
            trials{i} = OpenSimTrial(model, [], ...
                [results_folder filesep num2str(i)], grfs{i});
        elseif n_grfs == 0
            trials{i} = OpenSimTrial(model, motions{i}, ...
                [results_folder filesep num2str(i)]);
        else
            trials{i} = OpenSimTrial(model, motions{i}, ...
                [results_folder filesep num2str(i)], grfs{i});
        end
    end
end