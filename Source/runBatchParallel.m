function trials = runBatchParallel(analyses, trials, varargin)
% A parallelised version of runBatch. See runBatch for documentation. 
    
    % Iterate over the trials.
    parfor i=1:length(trials)
        
        % Perform analyses.
        trials{i}.run(analyses, varargin{:});  %#ok<PFBNS>
        
    end

end