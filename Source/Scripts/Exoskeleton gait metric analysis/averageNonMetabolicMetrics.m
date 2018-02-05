% The directory where the subject data is stored (as Matlab data).
load_dir = 'F:\one_subject_pipeline_metabolic';
save_dir = 'F:\one_subject_pipeline_metabolic\s1metrics.mat';

% The parameters we want to look at data for. 
subjects = [1:4,6:8];
feet = 1:2;
contexts = 2:2:10;
assistances = 1:3;
subjects = 1;
feet = 1;

% Load the subjects and store the metric information for each subject only.
for subject = subjects
    result = loadSubject(load_dir, subject);
    MetricsData.(['Subject' num2str(subject)]) = result.MetricsData;
    clear('result');
end

% Consider only the non-metabolic metrics in this script, as the behaviour
% will be slightly different for those.
metric_names = fieldnames(MetricsData.( ...
    ['Subject' num2str(subjects(1))]).AvgJointPowers);

% The following is only necessary if you have metabolic data in what you're
% loading. 
% metric_names = metric_names(1:end-2);

for nmetric = 1:length(metric_names)
    outer_observations = [];
    outer_means = [];
    outer_stds = [];
    for context = contexts
        inner_means = [];
        inner_stds = [];
        inner_observations = [];
        for assistance = assistances
            values = [];
            for subject = subjects
                for foot = feet
                    data = MetricsData.(['Subject' num2str(subject)]).AvgJointPowers. ...
                        (metric_names{nmetric}){foot, context, assistance};
                    for instance = 1:length(data)
                        values = [values; data{instance}];
                    end
                end
            end
            inner_means = [inner_means; mean(values)];
            inner_stds = [inner_stds; std(values)];
            inner_observations = [inner_observations; values];
        end
        outer_means = [outer_means, inner_means];
        outer_stds = [outer_stds, inner_stds];
        outer_observations = [outer_observations, inner_observations];
    end
    nmbob = size(outer_observations,1)/length(assistances);
    [~,~,stats] = anova2(outer_observations, nmbob, 'off');
    col_diffs = multcompare(stats, 'Estimate', 'column', 'Display', 'off');
    row_diffs = multcompare(stats, 'Estimate', 'row', 'Display', 'off');
    
    % Create the metric.
    Metrics.(metric_names{nmetric}) = metric(metric_names{nmetric}, ...
        outer_means, outer_stds, nmbob, col_diffs, row_diffs);
end

% Save the final result.
save(save_dir, 'Metrics');