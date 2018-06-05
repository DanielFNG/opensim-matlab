function result = calculateAvgJointPower(CMC, joint, muscles, weight)
% This function accepts a CMCResult, a joint name, a muscle struct, and the 
% weight of the subject. The muscle struct should have two fields:
%   uniarticular - cell array of names of uniarticular muscles crossing
%                  this joint
%   biarticular - info on the biarticular muscles, in particular...
%       .muscles - cell array of names of biarticular muscles crossing 
%                  this joint
%       .joints - cell array of names of the other joints crossed by the
%                 muscle
% This function calculates the average metabolic power across the given
% joint over the gait cycle defined by the CMC result. The result ends up
% being normalised to the subject weight (though this happens internally in
% calculateAvgMusclePower).

    % Calculate the average powers of the uniarticular muscles, then sum
    % to get the total.
    n_uniarticular = length(muscles.uniarticular);
    uniarticular_powers = zeros(1,n_uniarticular);
    for i=1:n_uniarticular
        uniarticular_powers(1,i) = ...
            calculateAvgUniMusclePower(CMC, muscles.uniarticular{i}, weight);
    end
    total_uniarticular_power = sum(uniarticular_powers);
    
    % Calculate the average powers of the biarticular muscles, then sum to
    % get the total. 
    n_biarticular = length(muscles.biarticular.muscles);
    biarticular_powers = zeros(1,n_biarticular);
    for i=1:n_biarticular
        biarticular_powers(1,i) = ...
            calculateAvgBiMusclePower(CMC, ...
            muscles.biarticular.muscles{i}, joint, ...
            muscles.biarticular.joints{i}, weight);
    end
    total_biarticular_power = sum(biarticular_powers);
            
    % Sum the powers of the uniarticular and biarticular muscles.
    result = total_uniarticular_power + total_biarticular_power;

end

