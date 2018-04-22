classdef metric < handle
    
    properties (SetAccess = private)
        name
        sample_size 
        means  
        sdevs 
        row_diffs
        col_diffs
        n_rows
        n_cols
        row_sig_diffs
        col_sig_diffs
        p_value = 0.05
        row_labels
        col_labels
        row_descriptor = 'row'
        col_descriptor = 'column'
    end
        
    properties (SetAccess = private, GetAccess = private)
        base_row = 1 % Assume baseline corresponds to (1,1)
        base_col = 1
        combined_means
        combined_sdevs
    end
    
    methods 
        
        function obj = metric(name, means, sdevs, sample_size, ...
                col_diffs, row_diffs, row_descriptor, col_descriptor, row_labels, col_labels, baseline)
            if nargin > 0
                obj.name = name;
                if nargin >= 6
                    obj.means = means;
                    obj.sdevs = sdevs;
                    obj.sample_size = sample_size;
                    obj.row_diffs = row_diffs;
                    obj.n_rows = size(row_diffs, 1);
                    obj.col_diffs = col_diffs;
                    obj.n_cols = size(col_diffs, 1);
                    obj = obj.identifySignificantDifferences();
                    obj = obj.calcCombinedMeansAndSdevs();
                    if nargin >= 8
                        obj.row_descriptor = row_descriptor;
                        obj.col_descriptor = col_descriptor;
                        obj.row_labels = row_labels;
                        obj.col_labels = col_labels;
                        if nargin == 11
                            obj.base_row = baseline(1);
                            obj.base_col = baseline(2);
                        end
                    else
                        obj.assignDefaultLabels();
                    end
                else
                    error('Non-empty metrics require 6+ arguments.');
                end
            end
        end
        
        % Assigns default labelling to the rows and columns e.g. row1, 
        % col1, etc.
        function assignDefaultLabels(obj)
            for i=1:obj.n_rows
                obj.row_labels{i} = ['row' num2str(i)];
            end
            for i=1:obj.n_cols
                obj.col_labels{i} = ['col' num2str(i)];
            end
        end
        
        % Calculate the significant difference matrices. These identify 
        % which combinations of rows/columns exhibit significant differences.
        % For example row_sig_diffs(1,2) = 1 => there is a significant 
        % difference between row 1 and row 2. The default is 0, meaning 
        % no significant differences. The matrix is left as upper
        % triangular.
        function identifySignificantDifferences(obj)
            
            obj.row_sig_diffs = zeros(obj.n_rows);
            obj.col_sig_diffs = zeros(obj.n_cols);
            
            for i=1:size(obj.col_diffs,1)
                if obj.col_diffs(i,6) < obj.p_value
                    obj.col_sig_diffs(obj.col_diffs(i, 1), obj.col_diffs(i, 2)) = 1;
                end
            end
            
            for i=1:size(obj.row_diffs,1)
                if obj.row_diffs(i,6) < obj.p_value 
                    obj.row_sig_diffs(obj.row_diffs(i, 1), obj.row_diffs(i, 2)) = 1;
                end
            end         
        end
        
        % This calculates obj.combined_means, which is a map from a label
        % (corresponding to either a row or column) on to the combined 
        % mean for that label.
        %
        % For example, obj.combined_means('row1') is the mean value of
        % (row1,col1), (row2,col2), ... etc. And likewise for the column
        % labels.
        function calcCombinedMeansAndSdevs(obj)
            % Preallocate variables. 
            n_conditions = obj.n_rows + obj.n_cols;
            keys = cell(1, n_conditions);
            comb_means = zeros(1, n_conditions);
            comb_sdevs = zeros(1, n_conditions);
            
            % Calculate combined row and column means.
            comb_means(1:obj.n_rows) = mean(obj.means(1:end, :));
            comb_means(obj.n_rows + 1:obj.n_rows + obj.n_cols) = ...
                mean(obj.means(:, 1:end));
            
            % Calculate combined row sdevs. 
            for i=1:obj.n_rows
                % Increment assistance/context label for later use in Map.
                keys{i} = obj.row_labels{i};
                intRowVars(1:obj.n_cols) = metric.intermediateVariance(obj.sample_size, obj.sdevs(i, 1:end).^2, obj.means(i, 1:end), comb_means(i));
                comb_sdevs(i) = sqrt(sum(intRowVars)/(obj.n_cols*obj.sample_size - 1));
            end
            
            % Calculate combined column sdevs.
            for i=1:obj.n_cols
                keys{i + obj.n_rows} = obj.col_labels{i};
                intColVars(1:obj.n_rows) = metric.intermediateVariance(obj.sample_size, obj.sdevs(1:end, i).^2, obj.means(1:end, i), comb_means(i + obj.n_rows));
                comb_sdevs(i + obj.n_rows) = sqrt(sum(intColVars)/(obj.n_rows*obj.sample_size - 1));
            end
            
            % Create mappings from the condition labels to the combined
            % means and sdevs. 
            obj.combined_means = containers.Map(keys, comb_means);
            obj.combined_sdevs = containers.Map(keys, comb_sdevs);
        end
        
        % Calculate signed or absolute relative differences.
        function diff = calculateRelativeDifferences(obj, mode)
            diff = zeros(size(obj.means));
            baseline = obj.means(obj.base_row, obj.base_col);
            if strcmp(mode, 'unsigned')
                diff(:, :) = 100*(abs(obj.means(:, :) - baseline)/baseline);
            elseif strcmp(mode, 'signed')
                diff(:, :) = 100*(obj.means(:, :) - baseline)/baseline;
            else
                error('Unrecognised mode.');
            end
        end
        
        % Makes sense to use unsigned here to capture the magnitude of the
        % effect and avoid any cancellation. 
        function overall = calculateOverall(obj)
            diff = obj.calculateRelativeDifferences('unsigned');
            diff = reshape(diff,1,[]);
            overall = mean(diff);
        end
        
        % For a metric, calculates the average relative to assistance 
        % scenario (i.e. for each of 'NE', 'ET', 'EA', average 'BW':'SW')
        % or context (vice versa). 'direction' should be 'assistance' or 
        % 'context' depending on the mode. 
        function avg_1d = calculate1DAvg(obj, direction)
            diff = obj.calculateRelativeDifferences('unsigned');
            if strcmp(direction, obj.col_descriptor)
                avg_1d = 1:obj.n_cols;
                for i=1:obj.n_cols
                    avg_1d(i) = mean(diff(1:end,i));
                end
            elseif strcmp(direction, obj.row_descriptor)
                avg_1d = 1:obj.n_rows;
                for i=1:obj.n_rows
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
                if ~(strcmp(direction, obj.row_descriptor) || strcmp(direction, obj.col_descriptor))
                    error('If given direction should match either the column or row descriptor.');
                end
            end
            
            % Calculate Cohen's D for each significant differences, either
            % in one or both directions. 
            if ~(strcmp(direction, obj.col_descriptor))
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
            if ~(strcmp(direction, obj.row_descriptor))
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
            cohens_d = zeros(obj.n_rows,obj.n_cols);
            % over assistance levels and contexts...
            for i=1:obj.n_cols
                for j=1:obj.n_rows
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
        
        % Mode should be 'absolute', 'signed' or 'unsigned'.
        function plot3DBar(obj, mode)
            
            % Compute relative differences from the baseline. 
            if strcmp(mode, 'absolute')
                diff = obj.means;
            else
                diff = obj.calculateRelativeDifferences(mode);
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
                1:obj.n_cols, 'XTickLabel', obj.context_order, 'YTick', ...
                1:obj.n_rows, 'YTickLabel', obj.assistance_order);
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
        
        % Function for calculating the intermediate terms when calculating
        % combined variance of groups. Supports scalar or vector arguments
        % for variance, mean and overall mean. Sample size must be a 
        % scalar. 
        function result = intermediateVariance(...
                samples, variance, mean, overall_mean)
            result = ((samples - 1) * variance) ...
                + (samples * mean.^2) ...
                - (2 * samples * mean .* overall_mean) ...
                + (samples * overall_mean.^2);
        end
        
        % This function calculates Cohen's d for two groups of data, 
        % given the sample size, mean and variance of each group. 
        function result = cohensD(n1, m1, s1, n2, m2, s2)
            pooled_sdev = sqrt(((n1-1)*s1^2 + (n2-1)*s2^2)/(n1+n2-2));
            result = abs((m1 - m2)/pooled_sdev);
        end
        
    end
end
        