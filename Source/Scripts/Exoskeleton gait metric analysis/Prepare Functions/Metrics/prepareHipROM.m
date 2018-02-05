function result = prepareHipROM(~, ~, foot, context, assistance, result)
% Calculates the hip range of motion for a given subject and gait cycle 
% as indexed by a {foot, context, assistance} triple.

% Create correct label.
switch foot
    case 1
        label = 'hip_flexion_r';
    case 2
        label = 'hip_flexion_l';
end

% Gain access to the hip trajectories as set of data objects.
IK = result.IK.IK_array{foot, context, assistance};

% Create temp cell array.
temp{vectorSize(IK)} = {};

% Calculate hip ROM for each individual trajectory and save it.
for i=1:vectorSize(IK)
    temp{i} = calculateHipROM(IK{i}, label);
end

result.MetricsData.HipROM{foot, context, assistance} = temp;

end