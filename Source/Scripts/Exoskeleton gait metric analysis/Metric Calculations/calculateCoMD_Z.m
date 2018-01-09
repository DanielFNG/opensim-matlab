function result = calculateCoMD_Z(subject_data, foot, context, assistance)
% Calculates the CoM displacement in Z direction for a given subject and 
% gait cycle as indexed by a {foot, context, assistance} triple.

    % Gain access to the CoM trajectories as set of data objects.
    BK = subject_data.BodyKinematics{foot, context, assistance}.positions;
    result{vectorSize(BK)} = {};
    
    % Calculate CoM_Z.
    for i=1:vectorSize(BK)
        CoM = BK{i}.getDataCorrespondingToLabel('center_of_mass_Z');
        result{i} = max(CoM) - min(CoM);
    end
end
