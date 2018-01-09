function result = calculateCoMD_Y(subject_data, foot, context, assistance)
% Calculates the CoM displacement in Y direction for a given subject and 
% gait cycle as indexed by a {foot, context, assistance} triple.

    % Gain access to the CoM trajectories as set of data objects.
    BK = subject_data.BodyKinematics{foot, context, assistance}.positions;
    result{vectorSize(BK)} = {};
    
    % Calculate CoM_Y.
    for i=1:vectorSize(BK)
        CoM = BK{i}.getDataCorrespondingToLabel('center_of_mass_Y');
        result{i} = max(CoM) - min(CoM);
    end
end
