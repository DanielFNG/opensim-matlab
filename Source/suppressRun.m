function [trial, output] = suppressRun(trial, analyses, varargin)
    output = evalc('trial.run(analyses, varargin{:})');
end