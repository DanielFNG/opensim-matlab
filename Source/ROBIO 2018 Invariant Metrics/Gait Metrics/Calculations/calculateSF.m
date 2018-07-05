function result = calculateSF(grfs, label)
% Calculates the step frequency for a given grfs data and a label
% describing which foot to look at.
    
    % Isolate the stance phase of the step and the time column of the 
    % gait cycle.
    stance = isolateStancePhase(grfs, label);
    time = grfs.getTimeColumn();
    time = time(stance);
    
    % Calculate steps per minute. 
    result = 60/(time(end) - time(1));
end
