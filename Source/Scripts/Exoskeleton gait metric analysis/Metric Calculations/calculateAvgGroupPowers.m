function result = calculateAvgGroupPowers(CMC, labels, weight)

    % Compute the weight normalized average metabolic power for each muscle
    % in the group. Sum over the group to get the result. 
    result = 0;
    for i=1:length(labels)
        power = CMC.powers.getDataCorrespondingToLabel(labels{i});
        power(power <= 0) = 0;
        time = CMC.powers.Timesteps;
        result = result + trapz(time, power)/(weight*(time(end)-time(1)));
    end

end

