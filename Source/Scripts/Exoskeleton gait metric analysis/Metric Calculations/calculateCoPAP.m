function calculateCoPAP(subject_data, foot, context, assistance)
% Calculate CoPAP.

% Isolate grfs.
grfs = subject_data.grf{foot,context,assistance};

% Create results cell array.
result{vectorSize(grfs)} = {};

for i=1:vectorSize(grfs)
    cop = grfs{i}.getDataCorrespondingToLabel(...
        ['    ground_force' num2str(foot) '_px']);
    
    % Identify the stance phase. This may also lose points where the
    % stance phase curve crosses 0, but since we are only interested in the
    % min and max this is not an issue. 
    stance = isolateStancePhase(grfs{i}, foot);
    
    % Calculate CoPAP
    max_pk = max(cop(stance));
    min_pk = min(cop(stance));
    result{i} = max_pk - min_pk;
end

end

