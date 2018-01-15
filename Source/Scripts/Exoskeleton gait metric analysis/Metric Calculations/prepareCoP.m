function result = prepareCoP(foot, context, assistance, result)

% Define appropriate strings.
x_label = ['    ground_force' num2str(foot) '_px'];
z_label = ['    ground_force' num2str(foot) '_pz'];

% Isolate grfs. 
grfs = subject_data.grf{foot, context, assistance};

% Create cell array to hold temp results. 
temp_x{vectorSize(grfs)} = {};
temp_z{vectorSize(grfs)} = {};

for i=1:vectorSize(grfs)
    temp_x{i} = calculateCoPD(foot, grfs, x_label);
    temp_z{i} = calculateCoPD(foot, grfs, z_label);
end

result.Metrics.CoPAP = temp_x;
result.Metrics.CoPML = temp_z;

