% A test script to compare the functionality of Metric2D to metric. 

%% Create the input data. 

n_rows = 3;
n_columns = 5;
repetitions = 5*7*2; % Gait cycles, subjects, feet. 

X = rand(n_rows*repetitions, n_columns);

%% Additional processing required for metric.

means = zeros(n_rows, n_columns);
sdevs = zeros(n_rows, n_columns);
for i=1:n_rows
    means(i, :) = mean(X((i-1)*repetitions + 1:i*repetitions, :));
    sdevs(i, :) = std(X((i-1)*repetitions + 1:i*repetitions, :));
end
[~,~,stats] = anova2(X, repetitions, 'off');
col_diffs = multcompare(stats, 'Estimate', 'column', 'Display', 'off');
row_diffs = multcompare(stats, 'Estimate', 'row', 'Display', 'off');


%% Create a Metric2D and a metric.

testMetric2D = ...
    Metric2D('testMetric2D', X, repetitions, 'assistance', 'context');
testmetric = ...
    metric('testmetric', means, sdevs, repetitions, col_diffs, row_diffs);
