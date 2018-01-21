% This script performs the averaging process for the metrics, resulting in
% a mean and standard deviation for each (context, assistance) pair. 

root = 'F:\structs_with_metrics';
save_dir = 'F:\structs_with_metrics';

for subject=[1:4,6:8]
    data = loadSubject(root, subject);
    metric_labels = fieldnames(data.Metrics);
    for metric=1:vectorSize(metric_labels)
        for context=1:10
            for assistance=1:3
                values = [cell2mat(data.Metrics.(metric_labels{metric})...
                    .Values{1,context,assistance}), ...
                    cell2mat(data.Metrics.(metric_labels{metric}) ...
                    .Values{2,context,assistance})];
                if ~isempty(values)
                    data.Metrics.(metric_labels{metric}). ...
                        Mean{context, assistance} = mean(values);
                    data.Metrics.(metric_labels{metric}). ...
                        STD{context, assistance} = std(values);
                else
                    data.Metrics.(metric_labels{metric}). ...
                        Mean{context, assistance} = 'N/A';
                    data.Metrics.(metric_labels{metric}). ...
                        STD{context, assistance} = 'N/A';
                end
            end
        end
    end
    temp.(['subject' num2str(subject)]) = data;
    save([save_dir '\subject' num2str(subject) '.mat'], '-struct', 'temp');
    clear('data', 'temp');
end