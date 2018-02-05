function result = prepareSF(~, ~, foot, context, assistance, result)

    % Determine labelling based on foot.
    label = ['    ground_force' num2str(foot) '_vy'];
    
    % Isolate the grfs from the subject data.
    grfs = result.GRF{foot, context, assistance};
    
    % Create cell array of right size to hold results.
    temp{vectorSize(grfs)} = {};
    
    % Perform calculation.
    for i=1:vectorSize(grfs)
        temp{i} = calculateSF(grfs{i}, label);
    end
    
    % Store result.
    result.MetricsData.SF{foot, context, assistance} = temp;

end
