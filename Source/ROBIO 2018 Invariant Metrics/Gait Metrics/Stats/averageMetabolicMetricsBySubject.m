% The directory where the subject data is stored (as Matlab data).
load_dir = 'F:\offsets_cmc';

% The parameters we want to look at data for. 
subjects = [7,9];
contexts = 2:2:10;
assistances = 3;
feet = 1;

save_dir = [load_dir filesep 'metricsbysubject.mat'];

% Load the subjects and store the metric information for each subject only.
for subject = subjects
    result = loadSubject(load_dir, subject);
    MetricsData.(['Subject' num2str(subject)]) = result.MetricsData;
    clear('result');
end

% Identify the metrics we want to look at.
metric_names = fieldnames(MetricsData.( ...
    ['Subject' num2str(subjects(1))]).MusclePowers);

for subject = subjects
    subject_identifier = ['Subject' num2str(subject)];
    for nmetric = 1:(length(metric_names)-6)/2
        observations = [];
        means = [];
        stds = [];
        for context = contexts
            values = [];
            for assistance = assistances
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
            Metrics.(metric_names{nmetric}(1:end-2)).(subject_identifier).means = means;
            Metrics.(metric_names{nmetric}(1:end-2)).(subject_identifier).stds = stds;
            Metrics.(metric_names{nmetric}(1:end-2)).(subject_identifier).diffs = diffs;
        end
    end
    for nmetric = (length(metric_names)-5):2:(length(metric_names)-1)
        observations = [];
        means = [];
        stds = [];
        for context = contexts
            values = [];
            for assistance = assistances
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
        Metrics.(metric_names{nmetric}(1:end-2)).(subject_identifier).means = means;
        Metrics.(metric_names{nmetric}(1:end-2)).(subject_identifier).stds = stds;
        Metrics.(metric_names{nmetric}(1:end-2)).(subject_identifier).diffs = diffs;
    end
end

% Save the final result.
save(save_dir, 'Metrics');