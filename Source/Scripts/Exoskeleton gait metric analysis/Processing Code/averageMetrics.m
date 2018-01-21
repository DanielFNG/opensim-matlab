% This script performs the averaging process for the metrics, resulting in
% a mean and standard deviation for each (context, assistance) pair. 

root = 'F:\structs_with_metrics';
save_dir = 'F:\structs_with_metrics';

for subject=1
    data = loadSubject(root, subject);
    metric_labels = fieldnames(data.MetricsData);
    for n_metric=1:vectorSize(metric_labels)
        outer_means = [];
        outer_stds = [];
        for context=2:2:10
            inner_means = [];
            inner_stds = [];
            for assistance=1:3
                values = [cell2mat(data.MetricsData. ...
                    (metric_labels{n_metric}){1,context,assistance}), ...
                    cell2mat(data.MetricsData.(metric_labels{n_metric}) ...
                    {2,context,assistance})];
                inner_means = [inner_means; mean(values)];
                inner_stds = [inner_stds; std(values)];
            end
            outer_means = [outer_means, inner_means];
            outer_stds = [outer_stds, inner_stds];
        end
        data.Metrics.(metric_labels{n_metric}) = ...
            metric(metric_labels{n_metric}, outer_means, outer_stds);
    end
    temp.(['subject' num2str(subject)]) = data;
    save([save_dir '\subject' num2str(subject) '.mat'], '-struct', 'temp');
    clear('data', 'temp');
end