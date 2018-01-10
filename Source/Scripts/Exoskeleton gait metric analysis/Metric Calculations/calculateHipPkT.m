function result = calculateHipPkT(subject_data, foot, context, assistance)
% Calculate the peak to peak hip torque value.

% Account for left/right foot.
switch foot 
    case 1
        label = 'hip_flexion_r_moment';
    case 2
        label = 'hip_flexion_l_moment';
end

ID = subject_data.ID{foot, context, assistance}.ID_array;

% Calculate peak to peak hip torque. Dividing by weight
% for normalisation purposes.
for i=1:vectorSize(ID)
    hip = ID.id.getDataCorrespondingToLabel(label);
    result{i} = (max(hip) - min(hip))/subject_data.weight;
    if result{i} > 200
        error('HipPkT unreasonably high.');
    end
end

end

