function trials = runBatchParallel(analyses, trials, varargin)
% A parallelised version of runBatch. See runBatch for documentation. 
    
    % Iterate over the trials.
    parfor i=1:length(trials)
        
        % Access the specific trial.
        trial = trials{i};
        
        % Perform analyses.
        trial.run(analyses, varargin{:});  %#ok<PFBNS>
        
        % Assign back to trials array.
        trials{i} = trial;
        
        % Note: the above strategy of setting a local trial{i}, then
        % re-assigning, rather than using trials{i}.run(...), is necessary
        % to actually save the data in trials. A quirk of parfor. 
        
    end

end