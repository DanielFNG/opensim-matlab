function result = calculateAvgJointPowers(CMC, joint, weight)

    % Compute the weight normalized average metabolic power for each muscle
    % in the group. Sum over the group to get the result. 
    result = 0;
    for i=1:length(joint)
        power = CMC.powers.getDataCorrespondingToLabel(joint{i});
        power(power <= 0) = 0;
        time = CMC.powers.Timesteps;
        result = result + trapz(time, power)/(weight*(time(end)-time(1)));
    end

end

