function trials = runBatch(analyses, trials, varargin)
% Run a batch of OpenSim analyses.
%
%   Input arguments:
%       - analyses: ordered cell array of OpenSim analyses to be run
%       - trials: cell array of OpenSimTrial objects
%       - varargin: optional arguments to OpenSim analyses
    
    % Iterate over the trials.
    for i=1:length(trials)
        
        % Perform analyses.
        trials{i}.run(analyses, varargin{:});
        
    end
    
end