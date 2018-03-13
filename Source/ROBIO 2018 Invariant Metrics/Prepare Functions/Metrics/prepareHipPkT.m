function result = prepareHipPkT(~, ~, foot, context, assistance, result)
% Calculate the peak to peak hip torque value.

% Account for left/right foot.
switch foot 
    case 1
        label = 'hip_flexion_r_moment';
    case 2
        label = 'hip_flexion_l_moment';
end

ID = result.ID{foot, context, assistance};

% Create temp cell array.
temp{vectorSize(ID)} = {};

% Calculate peak to peak hip torque. Dividing by weight
% for normalisation purposes.
for i=1:vectorSize(ID)
    temp{i} = calculateHipPkT(ID{i}, result.Properties.Weight, label);
    if temp{i} > 200
        error('HipPkT unreasonably high.');
    end
end

result.MetricsData.HipPkT{foot, context, assistance} = temp;

end

