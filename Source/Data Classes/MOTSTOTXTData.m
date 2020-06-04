classdef (Abstract) MOTSTOTXTData < OpenSimData
% Abstract class for storing & working with OpenSim data in .mot or .sto format.
    
    properties (Access = protected)
        NonStateLabels = {'Time'};
    end

    methods
    
        function obj = MOTSTOTXTData(varargin)
        % Construct MOTSTOTXTData from (file) or from (values, header, labels). 
            obj@OpenSimData(varargin{:});
        end
        
    end
    
    methods (Static)
        
        function [values, labels, header] = load(filename)
        % Load data from file. 
        
            data_array = importdata(filename);
            values = data_array.data;
            if isfield(data_array, 'colheaders')
                labels = data_array.colheaders;
            else
                potential_labels = strsplit(data_array.textdata{end});
                if length(potential_labels) > 1
                    labels = potential_labels;
                else
                    error('Couldn''t find or parse labels.');
                end
            end
            header = data_array.textdata(1:end - 1, 1);
        
        end
        
        
    end
        
    methods (Access = protected)
        
        function printLabels(obj, fileID)
        % Print labels to file.
        
            spec = [repmat('%s\t', 1, length(obj.Labels) - 1) '%s\n'];
            fprintf(fileID, spec, obj.Labels{:});
        
        end
        
        function printValues(obj, fileID)
        % Print values to file.
            
            spec = [repmat('%.10g\t', 1, size(obj.Values, 2) - 1) '%.10g\n'];
            fprintf(fileID, spec, transpose(obj.Values));
        
        end
        
        function assignSpline(obj, timesteps, values)
        % Create values array from splined data & timesteps. 
        
            obj.Values = [timesteps, values];
        end
        
    end
        
    methods (Static, Access = protected)
        
        function header = convertHeader(input_header)
        % Convert header in to suitable form for Data object.
            
            header = input_header;
            
        end
        
        function labels = convertLabels(input_labels)
        % Convert labels in to suitable form for Data object. 
        
            labels = input_labels;
            
        end
        
        function values = convertValues(input_values)
        % Convert values in to suitable form for Data object. 
        
            values = input_values;
        
        end
    
    end

end