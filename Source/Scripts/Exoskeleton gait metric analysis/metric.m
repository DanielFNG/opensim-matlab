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
    end
end
        