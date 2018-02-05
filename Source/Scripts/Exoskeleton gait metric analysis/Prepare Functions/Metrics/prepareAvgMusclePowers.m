function result = prepareAvgMusclePowers(...
    ~, ~, foot, context, assistance, result)

import org.opensim.modeling.Model

gait2392 = Model([getenv('EXOPT_HOME') filesep 'Defaults' filesep ...
    'Model' filesep 'gait2392.osim']);
muscles = gait2392.getMuscles();
n_muscles = muscles.getSize();

% Gain access to the appropriate data.
cmc = result.CMC{foot, context, assistance};
weight = result.Properties.Weight;

% Create cell array to hold temporary results.
n_cmcs = vectorSize(cmc);
temp{n_muscles, n_cmcs} = {};

for i=1:n_muscles
    % Calculate the average metabolic power & store results. 
    for j=1:n_cmcs
        temp{i,j} = calculateAvgUniMusclePower(cmc{j}, ...
            char(muscles.get(i-1).getName()), weight);
    end
    
    % Store result properly.
    result.MetricsData.MusclePowers.(char(muscles.get(i-1).getName()))...
        {foot, context, assistance} = temp(i,:);
end

% Clear temp variable.
clear('temp');

end

