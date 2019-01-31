classdef TRCData < OpenSimData

    properties
        Filetype = '.trc' 
    end
    
    methods
    
        function obj = TRCData(varargin)
        % Construct TRCData from (file) or from (values, header, labels). 
            obj@OpenSimData(varargin{:});
        end
        
        % Updates header info to match the data object. Intended only to be
        % used as part of writeToFile function. 
        function updateHeader(obj)
            obj.Header{3} = [sprintf('%i\t', obj.Frequency, ...
                obj.CameraRate, obj.NFrames, (size(obj.Values, 2) - 2)/3)...
                sprintf('%s\t', obj.CameraUnits), sprintf('%i\t', ...
                obj.CameraRate), sprintf('%i\t', obj.Values(1,1)), ...
                sprintf('%i', obj.OrigNumFrames)];
      
        end
        
        function printLabels(obj, fileID)
        
            fprintf(fileID, '%s\t%s\t', ...
                char(obj.Labels(1)), char(obj.Labels(2)));
            for i=3:size(obj.Labels, 2)
                str = char(obj.Labels(i));
                if any(strcmp(str(end-1:end), {'_Y', '_Z'}))
                    fprintf(fileID, '%s\t', '');
                else
                    fprintf(fileID, '%s\t', str(1:end-2));
                end
            end
            fprintf(fileID, '\n\t\t');
            for i=3:3:length(obj.Labels) - 2
                fprintf(fileID, '%s\t', ['X' num2str(i/3)]);
                fprintf(fileID, '%s\t', ['Y' num2str(i/3)]);
                fprintf(fileID, '%s\t', ['Z' num2str(i/3)]);
            end
            fprintf(fileID, '\n\n');
            
        end
        
        function printValues(obj, fileID)
            
            for i=1:obj.NFrames
                fprintf(fileID, '%i\t', obj.Values(i, 1));
                for j=2:obj.NCols
                    fprintf(fileID, '%12.14f\t', obj.Values(i, j));
                end
            end
            
        end
    
    end
    
    methods (Static)
    
        function [values, header, labels] = parse(filename)
        
            [vals, head, lab] = TRCData.load(filename);
            
            header = header;
            
            labels{1} = lab{1};
            labels{2} = lab{2};
            k = 3;
            for i=3:length(lab) - 1
                labels{k} = [lab{i} '_X'];
                labels{k + 1} = [lab{i} '_Y'];
                labels{k + 2} = [lab{i} '_Z'];
                k = k + 3;
            end
            
            n_rows = length(vals);
            n_cols = length(labels);
            values = zeros(n_rows, n_cols);
            for i = 1:n_rows
                if size(vals{i}, 2) == n_cols
                    values(i, :) = str2double(vals{i});
                else
                    error('Data:Gaps', ...
                        'Error: gaps in marker data or missing markers.');
                end
            end
        
        end
    
        function [str_values, header, labels] = load(filename)
        
            id = fopen(filename);
            
            % Read in the header, which makes up the first 3 lines.
            for i=1:3
                header{i} = fgetl(id);
            end
            
            % Construct the labels.
            labels = strsplit(fgetl(id));
            
            % Now get the values.
            fgetl(id);  % The X/Y/Z line.
            count = 1;
            while true
                line = fgetl(id);
                if ~ischar(line)
                    break;
                end
                contents = strsplit(line);
                if length(contents) > 2  % Sometimes blank line reads as 2 chars
                    str_values{count} = strsplit(line);  %#ok<*AGROW>
                    % Sometimes the last column can be just a new line, which
                    % we don't want.
                    if isempty(str_values{count}{end})
                        str_values{count} = str_values{count}(1:end - 1);
                    end
                    count = count + 1;
                end
            end
            
            fclose(id);
        end
    
    end

end