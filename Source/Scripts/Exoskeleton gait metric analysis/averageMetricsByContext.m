% The directory where the subject data is stored (as Matlab data).
load_dir = 'D:\one_subject_pipeline_metabolic_by_context';

% The parameters we want to look at data for. 
subjects = [1:4,6:8];
contexts = 2:2:10;
assistances = 1:3;
feet = 1;

save_dir = [load_dir filesep 'allsubjectsmetricsbycontext.mat'];

% Load the subjects and store the metric information for each subject only.
for subject = subjects
    result = loadSubject(load_dir, subject);
    MetricsData.(['Subject' num2str(subject)]) = result.MetricsData;
    clear('result');
end

% Identify the metrics we want to look at.
metric_names = fieldnames(MetricsData.( ...
    ['Subject' num2str(subjects(1))]).MusclePowers);

for context = contexts
    context_identifier = ['Context' num2str(context)];
    for nmetric = 1:length(metric_names)
        observations = [];
        means = [];
        stds = [];
        for assistance = assistances
            values = [];
            for subject = subjects
                for foot = feet
                    data = MetricsData.(['Subject' num2str(subject)]).MusclePowers. ...
                        (metric_names{nmetric}){foot, context, assistance};
                    for instance = 1:length(data)
                        values = [values; data{instance}];
                    end
                end
            end
            means = [means, mean(values)];
            stds = [stds, std(values)];
            observations = [observations, values];
        end
        [~,~,stats] = anova1(observations, 'off');
        diffs = multcompare(stats, 'Display', 'off');
        
        % Create the metric.
        Metrics.(metric_names{nmetric}).(context_identifier).means = means;
        Metrics.(metric_names{nmetric}).(context_identifier).stds = stds;
        Metrics.(metric_names{nmetric}).(context_identifier).diffs = diffs;
    end
end

% Save the final result.
save(save_dir, 'Metrics');