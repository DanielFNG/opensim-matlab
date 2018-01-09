function result = calculateHipROM(subject_data, foot, context, assistance)
% Calculates the hip range of motion for a given subject and gait cycle 
% as indexed by a {foot, context, assistance} triple.

    % Gain access to the hip trajectories as set of data objects.
    IK = subject_data.IK{foot, context, assistance}.IK_array;
    result{vectorSize(IK)} = {};
    
    % Calculate hip ROM for each individual trajectory and save it.
    for i=1:vectorSize(IK)
        switch foot
            case 1
                label = 'hip_flexion_r';
            case 2
                label = 'hip_flexion_l';
        end
        motion = IK{i}.getDataCorrespondingToLabel(label);
        result{i} = max(motion) - min(motion);
    end
end