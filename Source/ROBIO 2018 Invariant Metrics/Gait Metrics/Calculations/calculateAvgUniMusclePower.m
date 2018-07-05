function result = calculateAvgUniMusclePower(CMC, muscle, weight)
% This function accepts a muscle name (string), a CMCResult, and a weight
% (e.g. the weight of the subject for which the CMC result was
% calculated). It calculates the average metabolic power of each muscle
% over the cycle, normalised by subject mass. This function assumes that
% the muscle is uniarticular (i.e. crosses only one joint). 

power = CMC.metabolics.getDataCorrespondingToLabel(...
    ['metabolics_' muscle]);
time = CMC.metabolics.Timesteps;
result = trapz(time, power)/(weight*(time(end)-time(1)));

end