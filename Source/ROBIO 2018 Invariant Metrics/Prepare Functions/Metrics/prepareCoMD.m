function result = prepareCoMD(~, ~, foot, context, assistance, result)

    % Gain access to the position trajectories of the bodies. 
    BK = result.BodyKinematics.positions{foot, context, assistance};
    
    % Create cell arrays to hold temporary results.
    temp_y{vectorSize(BK)} = {};
    temp_z{vectorSize(BK)} = {};
    
    % Calculate the CoMD metrics and store them in temp cell arrays. 
    for i=1:vectorSize(BK)
        temp_y{i} = calculateCoMD(BK{i}, 'Y');
        temp_z{i} = calculateCoMD(BK{i}, 'Z');
    end
    
    % Store results properly.
    result.MetricsData.CoMD_Y{foot, context, assistance} = temp_y;
    result.MetricsData.CoMD_Z{foot, context, assistance} = temp_z;
    
end
