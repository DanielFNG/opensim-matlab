classdef TRCData < OpenSimData
% Class for storing and working with OpenSim data in .trc format. 

    properties (SetAccess = protected)
        Filetype = '.trc'
    end
    
    properties (Access = protected)
        NonStateLabels = {'Frame#', 'Time'}
        OrigDataStartFrame
        CameraRate
        Units
    end
    
    methods
    
        function obj = TRCData(varargin)
        % Construct TRCData from (file) or from (values, header, labels). 
            obj@OpenSimData(varargin{:});
            info = strsplit(obj.Header{3});
            obj.OrigDataStartFrame = str2double(info{7});
            obj.CameraRate = str2double(info{2});
            obj.Units = info{5};
        end
        
        function convertUnits(obj, new_units)
        % Convert units of TRCData.
        %
        % Currently only supports conversion from/to m/mm and vice versa.
        
            if ~strcmp(obj.Units, new_units)
                switch obj.Units
                    case 'mm'
                        multiplier = 0.001;
                    case 'm'
                        multiplier = 1000;
                end

                % Convert the state data only.
                obj.scaleColumns(multiplier);
                obj.Units = new_units;
                
                % Update the header to store the new units.
                obj.updateHeader();
            end
            
        end
        
    end
    
    methods (Static)
    
        function [values, labels, header] = load(filename)
        % Load data from file. 
        %
        % importdata does not work for .trc files, so a more manual treatment 
        % is required. 
        
            id = fopen(filename);
            
            % Read in the header, which makes up the first 3 lines.
            header_len = 3;
            header = cell(1, header_len);
            for i=1:3
                header{i} = fgetl(id);
            end
            
            % Construct the labels.
            labels = strsplit(fgetl(id), '\t');
            if isempty(labels{end})
                labels(end) = [];
            end
            
            % Now get the values.
            fgetl(id);  % The X/Y/Z line.
            n = (length(labels) - 2)*3;
            spec = ['%f\t' repmat('%f\t', 1, n) '%f'];
            values = cell2mat(textscan(id, spec));
            
            fclose(id);
        end
    
    end
    
    methods (Access = protected)
        
        function updateHeader(obj)
        % Updates header info to match the data object.
        %
        % Should only be called by the writeToFile function.
            obj.Header{2} = sprintf('%s\t', 'DataRate', 'CameraRate', ...
                'NumFrames', 'NumMarkers', 'Units', 'OrigDataRate', ...
                'OrigDataStartFrame', 'OrigNumFrames');
            obj.Header{3} = [sprintf('%i\t', obj.Frequency, ...
                obj.CameraRate, obj.NFrames, (obj.NCols - 2)/3)...
                sprintf('%s\t', obj.Units), sprintf('%i\t', ...
                obj.OrigFrequency), sprintf('%i\t', obj.Values(1,1)), ...
                sprintf('%i', obj.OrigNumFrames)];
      
        end
        
        function setTimeLabel(obj)
            obj.TimeLabel = 'time';
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
            
            spec = ['%i\t' repmat('%.10g\t', 1, size(obj.Values, 2) - 2) ...
                '%.10g\n'];
            fprintf(fileID, spec, transpose(obj.Values));
            
        end
        
        function assignSpline(obj, timesteps, values)
        % Create values array from splined data & timesteps. 
        
            frames = 1:length(timesteps);
            obj.Values = [frames', timesteps, values];
        
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
                end_index = length(input_labels);
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
        
        function values = convertValues(input_values)
        % Convert values in to suitable format for Data objects.
            
            values = input_values;
        
        end
    
    end

end