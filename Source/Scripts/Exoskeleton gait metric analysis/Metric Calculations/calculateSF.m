function result = calculateSF(subject_data, foot, context, assistance)
% Calculates the step frequency for a given subject and gait cycle as 
% indexed by a {foot, context, assistance} triple.

    % Gain access to the input marker trajectories for both feet.
    these_markers = ...
        subject_data.IK{foot, context, assistance}.Input_Markers_array;
    other_markers = ...
        subject_data.IK{mod(foot,2) + 1, context, assistance}. ...
        Input_Markers_array;
    
    % Determine leading foot and set parameters accordingly. 
    if these_markers{1}.getStartTime() < other_markers{1}.getStartTime()
        n_results = vectorSize(these_markers);
        offset = 0;
    else
        n_results = vectorSize(these_markers) - 1;
        offset = 1;
    end
    
    % Create cell array for results. 
    result{n_results} = {};
        
    % Calculate step frequencies. 
    for i=1:n_results
        first_time = these_markers{i}.getStartTime();
        second_time = other_markers{i+offset}.getStartTime();
        result{i} = 1/(second_time - first_time);
    end
end