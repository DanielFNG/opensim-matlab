% The directory where the subject data is stored (as Matlab data).
load_dir_1 = 'F:\one_subject_pipeline_metabolic';
load_dir_2 = 'F:\Dropbox\PhD\Exoskeleton Metrics Compliant\Results';

% The parameters we want to look at data for. 
subjects = [1:4,6:8];
contexts = 2:2:10;
assistances = 1:3;
feet = 1;

save_dir = [load_dir_2 filesep 'allsubjectsmetricsbycontext.mat'];

% Load the subjects and store the metric information for each subject only.
for subject = subjects
    result = loadSubject(load_dir_1, subject);
    result_2 = loadSubject(load_dir_2, subject);
    temp_names = fieldnames(result.MetricsData.MusclePowers);
    for i=1:length(temp_names)
        for j=2:2:10
            MetricsData.(['Subject' num2str(subject)]).MusclePowers.(temp_names{i}){1, j, 1} = result.MetricsData.MusclePowers.(temp_names{i}){1, j, 1};
            MetricsData.(['Subject' num2str(subject)]).MusclePowers.(temp_names{i}){1, j, 2} = result.MetricsData.MusclePowers.(temp_names{i}){1, j, 2};
            MetricsData.(['Subject' num2str(subject)]).MusclePowers.(temp_names{i}){1, j, 3} = result_2.MetricsData.MusclePowers.(temp_names{i}){1, j, 3};
        end
    end
    clear('result');
    clear('result2');
end

% Identify the metrics we want to look at.
metric_names = fieldnames(MetricsData.( ...
    ['Subject' num2str(subjects(1))]).MusclePowers);

for context = contexts
    context_identifier = ['Context' num2str(context)];
    for nmetric = 1:(length(metric_names)-6)/2
        observations = [];
        means = [];
        stds = [];
        for assistance = assistances
            values = [];
            for subject = subjects
                for foot = feet
                    if strcmp(metric_names{nmetric}(1:end-2), 'glut_med1') || ...
                            strcmp(metric_names{nmetric}(1:end-2), 'glut_min1') || ...
                            strcmp(metric_names{nmetric}(1:end-2), 'add_mag1') || ...
                            strcmp(metric_names{nmetric}(1:end-2), 'glut_max1')
                        for i=1:3
                            data = MetricsData.(['Subject' num2str(subject)]).MusclePowers. ...
                                ([metric_names{nmetric}(1:end-3) num2str(i) '_r']){foot, context, assistance};
                            for instance = 1:length(data)
                                values = [values; data{instance}];
                            end
                            data = MetricsData.(['Subject' num2str(subject)]).MusclePowers. ...
                                ([metric_names{nmetric}(1:end-3) num2str(i) '_l']){foot, context, assistance};
                            for instance = 1:length(data)
                                values = [values; data{instance}];
                            end
                        end
                    elseif ~(strcmp(metric_names{nmetric}(end-2), '2') || strcmp(metric_names{nmetric}(end-2), '3')) 
                        data = MetricsData.(['Subject' num2str(subject)]).MusclePowers. ...
                            (metric_names{nmetric}){foot, context, assistance};
                        for instance = 1:length(data)
                            values = [values; data{instance}];
                        end
                        data = MetricsData.(['Subject' num2str(subject)]).MusclePowers. ...
                            ([metric_names{nmetric}(1:end-1) 'l']){foot, context, assistance};
                        for instance = 1:length(data)
                            values = [values; data{instance}];
                        end
                    end
                end
            end
            means = [means, mean(values)];
            stds = [stds, std(values)];
            observations = [observations, values];
        end
        if ~isempty(observations)
            [~,~,stats] = anova1(observations, [], 'off');
            diffs = multcompare(stats, 'Display', 'off');

            % Create the metric.
            Metrics.(metric_names{nmetric}(1:end-2)).(context_identifier).means = means;
            Metrics.(metric_names{nmetric}(1:end-2)).(context_identifier).stds = stds;
            Metrics.(metric_names{nmetric}(1:end-2)).(context_identifier).diffs = diffs;
        end
    end
    for nmetric = (length(metric_names)-5):2:(length(metric_names)-1)
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
                    data = MetricsData.(['Subject' num2str(subject)]).MusclePowers. ...
                        ([metric_names{nmetric}(1:end-1) 'l']){foot, context, assistance};
                    for instance = 1:length(data)
                        values = [values; data{instance}];
                    end
                end
            end
            means = [means, mean(values)];
            stds = [stds, std(values)];
            observations = [observations, values];
        end
        [~,~,stats] = anova1(observations, [], 'off');
        diffs = multcompare(stats, 'Display', 'off');
        
        % Create the metric.
        Metrics.(metric_names{nmetric}(1:end-2)).(context_identifier).means = means;
        Metrics.(metric_names{nmetric}(1:end-2)).(context_identifier).stds = stds;
        Metrics.(metric_names{nmetric}(1:end-2)).(context_identifier).diffs = diffs;
    end
end

% Save the final result.
save(save_dir, 'Metrics');