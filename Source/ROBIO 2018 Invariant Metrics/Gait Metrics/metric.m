classdef metric < handle
    
    properties %(SetAccess = private)
        name
        sample_size 
        means  
        sdevs 
        row_diffs
        col_diffs
        n_rows
        n_columns
        row_sig_diffs
        col_sig_diffs
        combined_means
        combined_sdevs
    end
        
    properties (SetAccess = private, GetAccess = private)
        p_value = 0.05
        assistance_order = {'NE', 'ET', 'EA-I', 'EA-C'}
        context_order = {'BW','UW','DW','FW','SW'}
    end
    
    methods 
        
        function obj = metric(name, means, sdevs, sample_size, ...
                col_diffs, row_diffs)
            if nargin > 0
                obj.name = name;
                if nargin == 6
                    obj.means = means;
                    obj.sdevs = sdevs;
                    obj.sample_size = sample_size;
                    obj.row_diffs = row_diffs;
                    obj.n_rows = size(row_diffs, 1);
                    obj.col_diffs = col_diffs;
                    obj.n_columns = size(col_diffs, 1);
                    obj = obj.identifySignificantDifferences();
                    obj = obj.calcCombinedMeansAndSdevs();
                else
                    error('A non-empty metric requires six arguments.');
                end
            end
        end
        
        % Calculate the significant difference matrices. These identify 
        % which combinations of rows/columns exhibit significant differences.
        % For example row_sig_diffs(1,2) = 1 => there is a significant 
        % difference between row 1 and row 2. The default is 0, meaning 
        % no significant differences. 
        function obj = identifySignificantDifferences(obj)
            
            obj.row_sig_diffs = zeros(obj.n_rows);
            obj.col_sig_diffs = zeros(obj.n_cols);
            
            for i=1:size(obj.col_diffs,1)
                if obj.col_diffs(i,6) < obj.p_value
                    obj.col_sig_diffs(obj.col_diffs(i, 1), obj.col_diffs(i, 2)) = 1;
                    obj.col_sig_diffs(obj.col_diffs(i, 2), obj.col_diffs(i, 1)) = 1;
                end
            end
            
            for i=1:size(obj.row_diffs,1)
                if obj.row_diffs(i,6) < obj.p_value 
                    obj.row_sig_diffs(obj.row_diffs(i, 1), obj.row_diffs(i, 2)) = 1;
                    obj.row_sig_diffs(obj.row_diffs(i, 2), obj.row_diffs(i, 1)) = 1;
                end
            end         
        end
        
        % This calculates obj.combined_means, which is a map from a label
        % (corresponding to either an assistance level or walking context)
        % on to the combined mean for that label.
        %
        % For example, obj.combined_means('NE') is the mean value of
        % (NE,BW), (NE,IW), (NE,DW), ... etc. And likewise for the context
        % labels. 
        function calcCombinedMeansAndSdevs(obj)
            n_assist = size(obj.assistance_order,2);
            n_context = size(obj.context_order,2);
            comb_means(1:obj.n_rows) = mean(obj.means(1:end, :));
            comb_means(1:obj.n_columns) = mean(obj.means(:, 1:end));
            
            for i=1:obj.n_rows
                temp = 0;
                for j=1:obj.context_order
                    temp = temp + metric.intermediateVariance(obj.sample_size, obj.sdevs(i, j)^2, obj.means(i, j), comb_means(i));
                end
                result = sqrt(temp/(d*obj.sample_size - 1));
                comb_sdevs = [comb_sdevs result];
            end
            
            for i=1:obj.n_rows
                intermediateVariances(1:obj.context_order) = metric.intermediateVariance(obj.sample_size, obj.sdevs(i, 1:obj.context_order)^2
            end
                  
            for i=1:n_assist
                keys{i} = obj.assistance_order{1,i};
                comb_means = [comb_means mean(obj.means(i,1:end))];
                comb_sdevs = [comb_sdevs obj.calcCombSdevs(...
                    comb_means(end), {'assistance', i})];
            end
            for i=1:n_context
                keys{i+n_assist} = obj.context_order{1,i};
                comb_means = [comb_means mean(obj.means(1:end,i))];
                comb_sdevs = [comb_sdevs obj.calcCombSdevs(...
                    comb_means(end), {'context', i})];
            end
            obj.combined_means = containers.Map(keys,comb_means);
            obj.combined_sdevs = containers.Map(keys,comb_sdevs);
        end
        
        function result = calcCombSdevs(obj, overall_mean, indices)
            if strcmp(indices{1}, 'assistance')
                assistance_level = indices{2};
                d = size(obj.context_order,2);
                temp = 0;
                for i=1:d
                    temp = temp + metric.intermediateVariance(...
                        obj.sample_size, ...
                        obj.sdevs(assistance_level,i)^2, ... % v = sdev^2
                        obj.means(assistance_level,i), overall_mean);
                end
            else
                context = indices{2};
                d = size(obj.assistance_order,2);
                temp = 0;
                for i=1:d
                    temp = temp + metric.intermediateVariance(...
                        obj.sample_size, obj.sdevs(i,context)^2, ...
                        obj.means(i,context), overall_mean);
                end
            end
            result = sqrt(temp/(d*obj.sample_size - 1));  % sdev = sqrt(V)
        end
        
        function diff = calculateSignedRelativeDifferences(obj)
            diff = zeros(size(obj.means));
            baseline = obj.means(1,1);
            for i=1:length(obj.assistance_order)
                for j=1:length(obj.context_order)
                    diff(i,j) = 100*(obj.means(i,j) - baseline)/baseline;
                end
            end
        end
        
        function diff = calculateRelativeDifferences(obj)
            diff = zeros(size(obj.means));
            baseline = obj.means(1,1); 
            for i=1:length(obj.assistance_order)
                for j=1:length(obj.context_order)
                    diff(i,j) = 100*(abs(obj.means(i,j) - baseline)/baseline);
                end
            end
        end
        
        function overall = calculateOverall(obj)
            diff = obj.calculateRelativeDifferences();
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
                avg_1d = 1:length(context_order);
                for i=1:length(context_order)
                    avg_1d(i) = mean(diff(1:end,i));
                end
            elseif strcmp(direction, 'assistance')
                avg_1d = 1:length(obj.assistance_order);
                for i=1:length(obj.assistance_order)
                    avg_1d(i) = mean(diff(i,1:end));
                end
            end
        end
        
        % Calculates the value of Cohen's d averaged across 
        % either assistance, context, or in both directions. 
        function result = calcCohensD(obj, direction)
            
            % Parse command line arguments to see whether to average across
            % a direction or do the overall average. 
            if nargin == 1
                direction = 0;
            elseif nargin ~= 2
                error('Require 1 or 2 arguments to calc anova cohens d.');
            else
                if ~(strcmp(direction, 'A') || strcmp(direction, 'C'))
                    error('If given direction should be ''A'' or ''C''.');
                end
            end
            
            % Calculate Cohen's D for each significant differences, either
            % in one or both directions. 
            if ~(strcmp(direction, 'C'))
                if isempty(obj.sig_diffs_A)
                    contribution_A = 0;
                else
                    contribution_A = [];
                    if ~isempty(obj.sig_diffs_A{1})
                        for i=1:size(obj.sig_diffs_A,1)
                            contribution_A = ...
                                [contribution_A obj.compCohensD(...
                                obj.sig_diffs_A{i,1}, obj.sig_diffs_A{i,2})];
                        end
                    end
                end
            end
            if ~(strcmp(direction, 'A'))
                contribution_C = [];
                if ~isempty(obj.sig_diffs_C{1})
                    for i=1:size(obj.sig_diffs_C,1)
                        contribution_C = ...
                            [contribution_C obj.compCohensD(...
                            obj.sig_diffs_C{i,1}, obj.sig_diffs_C{i,2})];
                    end
                end
            end
            
            % Choose what to return based on the provided direction.
            if direction == 0
                result = mean([contribution_A contribution_C]);
            elseif strcmp(direction, 'A')
                result = mean(contribution_A);
            else % we already checked direction is either 'A', 'C', or set to 0
                result = mean(contribution_C);
            end
        end
        
        % Calculates the absolute value of Cohen's d averaged across 
        % either assistance, context, or in both directions. 
        function result = calcAbsCohensD(obj, direction)
            % Check that the significant difference info has been input.
%             if isempty(obj.sig_diffs_A)
%                 error(['The Cohen''s d calculation'...
%                     ' requires knowledge of significant differences.'...
%                     ' See inputSignificantDifferences method.']);
%             end
            
            % Parse command line arguments to see whether to average across
            % a direction or do the overall average. 
            if nargin == 1
                direction = 0;
            elseif nargin ~= 2
                error('Require 1 or 2 arguments to calc anova cohens d.');
            else
                if ~(strcmp(direction, 'A') || strcmp(direction, 'C'))
                    error('If given direction should be ''A'' or ''C''.');
                end
            end
            
            % Calculate Cohen's D for each significant differences, either
            % in one or both directions. 
            if ~(strcmp(direction, 'C'))
                contribution_A = [];
                if ~strcmp(obj.sig_diffs_A{1}, 'n/a')
                    for i=1:size(obj.sig_diffs_A,1)
                        contribution_A = ...
                            [contribution_A abs(obj.compCohensD(...
                            obj.sig_diffs_A{i,1}, obj.sig_diffs_A{i,2}))];
                    end
                end
            end
            if ~(strcmp(direction, 'A'))
                contribution_C = [];
                if ~strcmp(obj.sig_diffs_C{1}, 'n/a')
                    for i=1:size(obj.sig_diffs_C,1)
                        contribution_C = ...
                            [contribution_C abs(obj.compCohensD(...
                            obj.sig_diffs_C{i,1}, obj.sig_diffs_C{i,2}))];
                    end
                end
            end
            
            % Choose what to return based on the provided direction.
            if direction == 0
                result = mean([contribution_A contribution_C]);
            elseif strcmp(direction, 'A')
                result = mean(contribution_A);
            else % we already checked direction is either 'A', 'C', or set to 0
                result = mean(contribution_C);
            end
        end
        
        % Calculates Cohen's d between the groups of data specified by 
        % label1 and label2.
        function result = compCohensD(obj, label1, label2)
            if any(strcmp(label1, obj.assistance_order))
                q = size(obj.context_order,2);
            else
                q = size(obj.assistance_order,2);
            end
            n = obj.sample_size*q;
            mean1 = obj.combined_means(label1);
            mean2 = obj.combined_means(label2);
            sdev1 = obj.combined_sdevs(label1);
            sdev2 = obj.combined_sdevs(label2);
            result = metric.cohensD(n,mean1,sdev1,n,mean2,sdev2);
        end
              
        function cohens_d = calculateCohensD_tTests(obj)
            % t tests comparing means to baselines
            % 14 effect size results for each metric. Start off with a 
            % 5 x 3 matrix for convenience. 
            cohens_d = zeros(length(obj.assistance_order),length(obj.context_order));
            % over assistance levels and contexts...
            for i=1:length(obj.context_order)
                for j=1:length(obj.assistance_order)
                    % Don't compare the baseline to itself.
                    if ~ (i == 1 && j == 1)
                        % Calculate pooled standard deviation.
                        ss = obj.sample_size;
                        pool = sqrt(((ss-1)*obj.sdevs(1,1)^2 + (ss-1)*obj.sdevs(j,i)^2)/(2*ss-2));
                        cohens_d(j,i) = (obj.means(1,1) - obj.means(j,i))/pool;
                    end
                end
            end
        end
        
        function plot3DBar(obj, mode)
            
            % Compute relative differences from the baseline. 
            if strcmp(mode, 'absolute')
                diff = obj.means;
            elseif strcmp(mode, 'relative_signed')
                diff = obj.calculateSignedRelativeDifferences;
            elseif strcmp(mode, 'relative')
                diff = obj.calculateRelativeDifferences; 
            else
                error('Mode for plot3DBar not recognised.');
            end
            
            % Set dimensions.
            b = figure;
            b.Units = 'centimeters';
            set(b, 'Position', [2 2 25 15]);
            ax = axes('Parent', b);
            
            % Create a bar plot.
            b = bar3(diff);
            
            % Create the color bar.
            colormap('parula');
            colorbar('peer',ax,'Position',[0.890396659707724 ...
                0.198050314465409 0.031513569937367 0.666729559748428]);
            
            % Change the colours of the bars accordingly. 
            for k=1:length(b)
                b(k).CData = b(k).ZData;
                b(k).FaceColor = 'interp';
            end
            
            % Add the significant difference lines. 
            hold on;
            obj.plotSignificantDifferences(diff);
            hold off
            
            obj.context_order{2} = 'UW';
            
            % Handle labels etc.
            xlabel('Walking context', 'FontWeight', 'bold');
            zlabel('% difference from baseline', 'FontWeight', 'bold');
            ylabel('Assistance Level', 'FontWeight', 'bold');
            set(ax, 'FontSize', 20, 'FontWeight', 'bold', 'XTick', ...
                1:length(obj.context_order), 'XTickLabel', obj.context_order, 'YTick', ...
                1:length(obj.assistance_order), 'YTickLabel', obj.assistance_order);
            words = strsplit(obj.name(1:end-2), '_');
            if length(words) > 1
                for i=1:length(words)
                    if strcmp(words{i}(end), '1')
                        words{i} = [words{i}(1:end-1) '.'];
                    else
                        words{i} = [words{i} '.'];
                    end
                end
            end
            new_name = strjoin(words);
            title([upper(new_name(1)) new_name(2:end)])
            
            ylim([0 5]);
                    
        end
        
        function plotSignificantDifferences(obj, vals)
            j = 0.1;
            for i=1:size(obj.col_diffs,1)
                if obj.col_diffs(i,6) < obj.p_value
                    mx = max(max(vals)) + j*max(max(vals));
                    j = j + 0.2;
                    x = [obj.col_diffs(i,1); obj.col_diffs(i,2)];
                    y = zeros(2);
                    z = ones(1,2)*mx;
                    plot3(x,y,z,'-k.','linewidth',1);
                end
            end
            
            j = 0.1;
            for i=1:size(obj.row_diffs,1)
                if obj.row_diffs(i, 6) < obj.p_value
                    mx = max(max(vals)) + j*max(max(vals));
                    j = j + 0.2;
                    x = ones(1,2)*5.4;
                    y = [obj.row_diffs(i,1); obj.row_diffs(i,2)];
                    z = ones(1,2)*mx;
                    plot3(x,y,z,'-k.','linewidth',1);
                end
            end  
        end
        
    end
    
    methods (Static)
        
        function index = mapLabel(string)
            if strcmp(string, 'NE') || strcmp(string, 'BW')
                index = 1;
            elseif strcmp(string, 'ET') || strcmp(string, 'IW')
                index = 2;
            elseif strcmp(string, 'EA') || strcmp(string, 'DW') || strcmp(string, 'EA-I')
                index = 3;
            elseif strcmp(string, 'FW') || strcmp(string, 'EA-C')
                index = 4;
            elseif strcmp(string, 'SW')
                index = 5;
            else
                error('String not recognised.')
            end
        end
        
        % Function for calculating the intermediate terms when calculating
        % combined variance of groups. 
        function result = intermediateVariance(...
                samples, variance, mean, overall_mean)
            result = ((samples - 1) * variance) ...
                + (samples * mean^2) ...
                - (2 * samples * mean * overall_mean) ...
                + (samples * overall_mean^2);
        end
        
        % This function calculates Cohen's d for two groups of data, 
        % given the sample size, mean and variance of each group. 
        function result = cohensD(n1, m1, s1, n2, m2, s2)
            pooled_sdev = sqrt(((n1-1)*s1^2 + (n2-1)*s2^2)/(n1+n2-2));
            result = abs((m1 - m2)/pooled_sdev);
        end
        
    end
end
        