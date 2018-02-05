function result = prepareCoPD(~, ~, foot, context, assistance, result)

% Define labels based on foot.
f_label = ['    ground_force' num2str(foot) '_vy'];
x_label = ['    ground_force' num2str(foot) '_px'];
z_label = ['    ground_force' num2str(foot) '_pz'];

% Isolate grfs. 
grfs = result.GRF{foot, context, assistance};

% Create cell array to hold temp results. 
temp_x{vectorSize(grfs)} = {};
temp_z{vectorSize(grfs)} = {};

for i=1:vectorSize(grfs)
    temp_x{i} = calculateCoPD(grfs{i}, f_label, x_label);
    temp_z{i} = calculateCoPD(grfs{i}, f_label, z_label);
end

result.MetricsData.CoPAP{foot, context, assistance} = temp_x;
result.MetricsData.CoPML{foot, context, assistance} = temp_z;

