function result = calculateSF(subject_data, foot, context, assistance)
% Calculates the step frequency for a given subject and gait cycle as 
% indexed by a {foot, context, assistance} triple.

    % Determine labelling based on foot.
    if foot == 1 
        label = '    ground_force2_vy';
    elseif foot == 2
        label = '    ground_force1_vy';
    end
    
    % Access grfs and grf time column separately.
    grfs = subject_data.GRF{foot, context, assistance};
    time = grfs.getTimeColumn();

    % Get start and end time - end time is the last time in the array at
    % which the vertical grf is equal to 0.
    start_time = grfs.getStartTime();
    end_time = ...
        time(find(grfs.getDataCorrespondingToLabel(label)==0,1,'last'));
    
    % Calculate steps per minute. 
    result = 60/(end_time - start_time);
end
