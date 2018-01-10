function result = calculateHipPkT(subject_data, foot, context, assistance)
% Calculates the hip peak to peak torques for a given subject and gait 
% cycle as indexed by a {foot, context, assistance} triple.

    % Gain access to the hip torques as set of data objects.
    ID = subject_data.ID{foot, context, assistance}.ID_array;
    result{vectorSize(ID)} = {};
    
    switch foot
        case 1
            label = 'hip_flexion_r_moment';
        case 2
            label = 'hip_flexion_l_moment';
    end
    
    % Calculate hip peak to peak torque for each individual trajectory and 
    % save it.
    for i=1:vectorSize(ID)
        torques = ID{i}.id.getDataCorrespondingToLabel(label);
        result{i} = max(torques) - min(torques);
    end
end