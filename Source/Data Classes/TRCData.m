classdef TRCData < OpenSimData
% Class for storing and working with OpenSim data in .trc format. 

    properties (SetAccess = protected)
        Filetype = '.trc' 
    end
    
    properties (Access = protected)
        CameraRate = 100; % Fixed camera rate for Vicon cameras.
        CameraUnits = 'mm'; % Fixed camera units for Vicon cameras.
    end
    
    methods
    
        function obj = TRCData(varargin)
        % Construct TRCData from (file) or from (values, header, labels). 
            obj@OpenSimData(varargin{:});
        end
        
    end
    
    methods (Static)
    
        function [str_values, labels, header] = load(filename)
        % Load data from file. 
        %
        % importdata does not work for .trc files, so a more manual treatment 
        % is required. 
        
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
    
    methods (Access = protected)
        
        function updateHeader(obj)
        % Updates header info to match the data object.
        %
        % Should only be called by the writeToFile function. 
            obj.Header{3} = [sprintf('%i\t', obj.Frequency, ...
                obj.CameraRate, obj.NFrames, (size(obj.Values, 2) - 2)/3)...
                sprintf('%s\t', obj.CameraUnits), sprintf('%i\t', ...
                obj.CameraRate), sprintf('%i\t', obj.Values(1,1)), ...
                sprintf('%i', obj.OrigNumFrames)];
      
        end
        
        function printLabels(obj, fileID)
        % Print labels to file. 
        
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
        % Print values to file.
            
            for i=1:obj.NFrames
                fprintf(fileID, '%i\t', obj.Values(i, 1));
                for j=2:obj.NCols-1
                    fprintf(fileID, '%.10g\t', obj.Values(i, j));
                end
                fprintf(fileID, '%.10g\n', obj.Values(i, obj.NCols));
            end
            
        end
        
        function assignSpline(obj, timesteps, values)
        % Create values array from splined data & timesteps. 
        
            frames = 1:length(timesteps);
            obj.Values = [frames, timesteps, values];
        
        end
        
    end
    
    methods (Static, Access = protected)
  
        function header = convertHeader(input_header)
        % Convert header in to suitable form for Data object.
        
            header = input_header;
        
        end
    
        function labels = convertLabels(input_labels)
        % Convert input labels in to Cartesian form for TRC file. 
        %
        % Supports both labels from TRCData.load - in which case the Frame#
        % and time entries are parsed - and also a generic cell array of 
        % spatial labels.
        
            if strcmp(input_labels{1}, 'Frame#')
                labels{1} = input_labels{1};
                labels{2} = input_labels{2};
                start_index = 3;
                end_index = length(input_labels) - 1;
            else
                start_index = 1;
                end_index = length(input_labels);
            end
            k = start_index;
            for i=start_index:end_index
                labels{k} = [input_labels{i} '_X'];
                labels{k + 1} = [input_labels{i} '_Y'];
                labels{k + 2} = [input_labels{i} '_Z'];
                k = k + 3;
            end
        
        end
        
        function values = convertValues(input_values, input_labels)
        % Convert values in to suitable format for Data objects.
        
            n_rows = length(input_values);
            n_cols = length(input_labels);
            values = zeros(n_rows, n_cols);
            for i = 1:n_rows
                if size(input_values{i}, 2) == n_cols
                    values(i, :) = str2double(input_values{i});
                else
                    error('Data:Gaps', ...
                        'Error: gaps in marker data or missing markers.');
                end
            end
        
        end
    
    end

end