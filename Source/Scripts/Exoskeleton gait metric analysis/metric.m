classdef metric
    
    properties (SetAccess = private)
        name
        significant_differences_A
        significant_differences_C
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
        
        function obj = inputSignificantDifferences(obj)
            % This method provides a way to manually input the significant
            % differences for each metric. What results is 2 2D cell array
            % accessed using obj.significant_differences_A or _C. 
            % The first dimension is how many differences there are in the
            % respective direction.
            % The second dimension also has 2 elements, the first of which
            % is the 'from' and the second the 'to', for example a
            % significant difference from NE to ET, for example. In
            % practice which is from and which is to won't matter since we
            % will only consider absolute Cohen's d for simplicity. 
            display(['Please input all significant differences along'... 
                'the assistance direction. Input ''end'' to finish. You'...
                'will be prompted using ''From:'' and ''To:''. Give'...
                'the correct acronym in each case.']);
            n_x = 0;
            while true 
                x_f = input('From:\n', 's');
                if strcmp(x_f, 'end')
                    if n_x == 0
                        obj.significant_differences_A{1,1} = 'n/a';
                    end
                    break
                end
                n_x = n_x + 1;
                x_t = input('To:\n', 's');
                obj.significant_differences_A{n_x,1} = x_f;
                obj.significant_differences_A{n_x,2} = x_t;
            end
            display('Now do the same but along context.');
            n_y = 0;
            while true
                y_f = input('From:\n', 's');
                if strcmp(y_f, 'end')
                    if n_y == 0
                        obj.significant_differences_C{1,1} = 'n/a';
                    end
                    break
                end
                n_y = n_y + 1;
                y_t = input('To:\n', 's');
                obj.significant_differences_C{n_y,1} = y_f;
                obj.significant_differences_C{n_y,2} = y_t;
            end
        end
        
        function printValues(obj)
            values = obj.values;
            display(values);
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
              
        function cohens_d = calculateCohensD_tTests(obj)
            % t tests comparing means to baselines
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
        
        function cohens_d = calculateCohensD_anova(obj, direction)
            % ANOVA method 
            % For each of both directions (assistance/context), and for
            % each significant difference pair, calculate Cohen's D between
            % the pair (where the 'other' direction is averaged over).
            
            % The optional argument 'direction' should evalute to 'A' if 
            % only caring about the along-assistance average, or 'C' if the
            % opposite. If not present the overall average is calculated. 
            if isempty(obj.significant_differences_A)
                error(['The ANOVA version of Cohen''s d calculation'...
                    ' requires knowledge of significant differences.'...
                    ' See inputSignificantDifferences method.']);
            end
            
            if nargin == 1
                direction = 0;
            elseif nargin ~= 2
                error('Require 1 or 2 arguments to calc anova cohens d.');
            else
                if ~(strcmp(direction, 'A') || strcmp(direction, 'C'))
                    error('If given direction should be ''A'' or ''C''.');
                end
            end
            
            % Along assistance direction.
            if ~strcmp(obj.significant_differences_A{1,1}, 'n/a')
                ss = 350; % 70 per mean, but all contexts avgd so x5
                contribution_A = [];
                for i=1:size(obj.significant_differences_A,1)
                    % Combine the means.
                    meanfrom = mean(obj.values(metric.mapLabel(...
                        obj.significant_differences_A{i,1},1:5)));
                    meanto = mean(obj.values(metric.mapLabel(...
                        obj.significant_differences_A{i,2},1:5)));
                    % Combine the sdevs. 
                    sdevfrom = 0;
                    sdevto = 0;
                    % Calculate the pooled standard deviation.
                    pool = sqrt(((ss-1)*sdevfrom^2 + (ss-1)*sdevto^2)/(2*ss-2));
                    % Calculate Cohen's d for this difference.
                    cohens_d = (meanfrom - meanto)/pool;
                    % Add it to the array.
                    contribution_A = [contribution_A cohens_d];
                end
            else
                contribution_A = 0;
            end
            % Compute the total contribution along assistance, as the mean
            % of the list from the previous loop (or 0 if no diffs).
            contribution_A = mean(contribution_A);
            
            % Along context direction. 
            if ~strcmp(obj.significant_differences_C{1,1}, 'n/a')
                ss = 210; % 70 per mean, but all ass avgd so x3
                contribution_C = [];
                for i=1:size(obj.significant_differences_C,1)
                    % Combine the means.
                    % Combine the sdevs.
                    % Calculate the pooled standard deviation.
                    % Calculate Cohen's d for this difference.
                    % Add it to the array.
                end
            else
                contribution_C = 0;
            end
            % Compute the total contribution along context, as the mean 
            % of the list from the previous loop (or 0 if no diffs).
            contribution_C = mean(contribution_C);
            
            % Choose what to return based on the provided direction.
            if direction == 0
                cohens_d = contribution_A + contribution_C;
            elseif strcmp(direction, 'A')
                cohens_d = contribution_A;
            else % we already checked direction is either 'A', 'C', or set to 0
                cohens_d = contribution_C;
            end
        end
        
    end
    
    methods (Static)
        
        function index = mapLabel(string)
            if strcmp(string, 'NE') || strcmp(string, 'BW')
                index = 1;
            elseif strcmp(string, 'ET') || strcmp(string, 'IW')
                index = 2;
            elseif strcmp(string, 'EA') || strcmp(string, 'DW')
                index = 3;
            elseif strcmp(string, 'FW')
                index = 4;
            elseif strcmp(string, 'SW')
                index = 5;
            else
                error('String not recognised.')
            end
        end
        
    end
end
        