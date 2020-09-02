function trials = runBatchParallel(analyses, trials, varargin)
% A parallelised version of runBatch. See runBatch for documentation. 
    
    % Iterate over the trials.
    parfor i=1:length(trials)
        
        % Access the specific trial.
        trial = trials{i};
        
        % Attempt to process the trial. If we fail, store a 0 in the trials
        % array.
        try
            % Perform analyses.
            trial.run(analyses, varargin{:});  %#ok<PFBNS>

            % Assign back to trials array.
            trials{i} = trial;
        catch
            % A message 
            trials{i} = 0;
        end
        
        % Note: the above strategy of setting a local trial{i}, then
        % re-assigning, rather than using trials{i}.run(...), is necessary
        % to actually save the data in trials. A quirk of parfor. 
        
    end
    
    % Prune the trials which failed to process correctly.
    for i = length(trials):-1:1
        if trials{i} == 0
            trials(i) = [];
        end
    end

end