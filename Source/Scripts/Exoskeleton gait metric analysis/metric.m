classdef metric
    
    properties 
        name
    end
        
    properties (SetAccess = private, GetAccess = private)
        assistance_order = {'NE', 'EA', 'ET'}
        context_order = {'BW','IW','DW','FW','SW'}
        values = zeros(3,5)
        sdevs = zeros(3,5)
    end
    
    methods 
        
        function obj = metric(name)
            if nargin > 0
                obj.name = name;
            end
        end
        
        function obj = inputManually(obj)
            for i=1:size(obj.assistance_order,2)
                for j=1:size(obj.context_order,2)
                    obj.values(i,j) = input(...
                        ['Input value for metric: ', obj.name, ' for ', ...
                        obj.assistance_order{i}, ' and ', ...
                        obj.context_order{j}, ':\n']);
                    obj.sdevs(i,j) = input(...
                        ['Input sdev for metric: ', obj.name, ' for ', ...
                        obj.assistance_order{i}, ' and ', ...
                        obj.context_order{j}, ':\n']);
                end
            end
        end
        
        function printValues(obj)
            values = obj.values;
            display(values)
            sdevs = obj.sdevs;
            display(sdevs);
        end
        
        function diff = calculateRelativeDifferences(obj)
            diff = zeros(size(obj.values));
            baseline = obj.values(1,1); 
            for i=1:3
                for j=1:5
                    diff(i,j) = 100*(abs(obj.values(i,j) - baseline)/baseline);
                end
            end
        end
        
        function overall = calculateOverall(obj)
            diff = obj.calculateRelativeDifferences()
            diff = reshape(diff,1,[]);
            overall = mean(diff);
        end
        
        % For a metric, calculates the average relative to assistance 
        % scenario (i.e. for each of 'NE', 'ET', 'EA', average 'BW':'SW')
        % or context (vice versa). 'direction' should be 'assistance' or 
        % 'context' depending on the mode. 
        function avg_1d = calculate1DAvg(obj, direction)
            diff = obj.calculateRelativeDifferences();
            if strcmp(direction, 'context')
                avg_1d = 1:5;
                for i=1:5
                    avg_1d(i) = mean(diff(1:end,i));
                end
            elseif strcmp(direction, 'assistance')
                avg_1d = 1:3;
                for i=1:3
                    avg_1d(i) = mean(diff(i,1:end));
                end
            end
        end
              
        function cohens_d = calculateCohensD(obj)
            % 14 effect size results for each metric. Start off with a 
            % 5 x 3 matrix for convenience. 
            cohens_d = zeros(3,5);
            % over assistance levels and contexts...
            for i=1:5
                for j=1:3
                    % Don't compare the baseline to itself.
                    if ~ (i == 1 && j == 1)
                        % Calculate pooled standard deviation.
                        ss = 70;
                        pool = sqrt(((ss-1)*obj.sdevs(1,1)^2 + (ss-1)*obj.sdevs(j,i)^2)/(2*ss-2));
                        cohens_d(j,i) = (obj.values(1,1) - obj.values(j,i))/pool;
                    end
                end
            end
        end
        
    end
end
        