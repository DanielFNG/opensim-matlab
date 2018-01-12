function result = calculateCoPML(subject_data, foot, context, assistance)
% Calculate CoPML.

% Isolate grfs.
grfs = subject_data.GRF{foot,context,assistance};

% Create results cell array.
result{vectorSize(grfs)} = {};

for i=1:vectorSize(grfs)
    cop = grfs{i}.getDataCorrespondingToLabel(...
        ['    ground_force' num2str(foot) '_pz']);
    
    % Identify stance phase as the points with non-zero cop. The below is 
    % fine as this function never crosses 0. 
    stance = isolateStancePhase(grfs{i}, foot);
    
    % Calculate CoPML.
    max_pk = max(cop(stance(1):stance(end)));
    min_pk = min(cop(stance(1):stance(end)));
    result{i} = max_pk - min_pk;
end

end 