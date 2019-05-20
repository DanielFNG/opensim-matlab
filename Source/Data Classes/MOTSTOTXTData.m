classdef (Abstract) MOTSTOTXTData < OpenSimData
% Abstract class for storing & working with OpenSim data in .mot or .sto format.
    
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
            labels = data_array.colheaders;
            header = data_array.textdata(1:end - 1, 1);
        
        end
        
        
    end
        
    methods (Access = protected)
        
        function printLabels(obj, fileID)
        % Print labels to file.
        
            for i=1:obj.NCols
                fprintf(fileID, '%s\t', obj.Labels{i});
            end
            fprintf(fileID, '\n');
        
        end
        
        function printValues(obj, fileID)
        % Print values to file.
        
            for i=1:obj.NFrames
                for j=1:obj.NCols
                    fprintf(fileID,'%.10g\t', obj.Values(i,j));
                end
                fprintf(fileID,'\n');
            end
        
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
        
        function values = convertValues(input_values, ~)
        % Convert values in to suitable form for Data object. 
        
            values = input_values;
        
        end
    
    end

end