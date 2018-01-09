function result = calculateSW(subject_data, foot, context, assistance)
% Calculates the step width for a given subject and gait cycle as indexed 
% by a {foot, context, assistance} triple.

    % Define correct labels.
    if foot == 1
        this_label = 'R_HeelZ';
        other_label = 'L_HeelZ';
    elseif foot == 2
        this_label = 'L_HeelZ';
        other_label = 'R_HeelZ';
    else
        error('Foot index not recognised.');
    end        

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
        
    % Calculate step widths. 
    for i=1:n_results
        first_heel = ...
            these_markers{i}.getDataCorrespondingToLabel(this_label);
        second_heel = other_markers{i+offset}. ...
            getDataCorrespondingToLabel(other_label);
        result{i} = abs(second_heel(1) - first_heel(1));
    end
end