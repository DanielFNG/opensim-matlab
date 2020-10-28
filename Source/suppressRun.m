function [trial, output] = suppressRun(trial, analyses, args)
    output = evalc('trial.run(analyses, args{:})');
end