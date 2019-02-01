classdef (Abstract) MOTSTOData < OpenSimData
    
    methods
    
        function obj = MOTSTOData(varargin)
        % Construct MOTSTOData from (file) or from (values, header, labels). 
            obj@OpenSimData(varargin{:});
        end
        
        function printLabels(obj, fileID)
        
            for i=1:obj.NCols
                fprintf(fileID, '%s\t', obj.Labels{i});
            end
            fprintf(fileID, '\n');
        
        end
        
        function printValues(obj, fileID)
        
            for i=1:obj.NFrames
                for j=1:obj.NCols
                    fprintf(fileID,'%.10g\t', obj.Values(i,j));
                end
                fprintf(fileID,'\n');
            end
        
        end
        
        function splined_obj = assignSpline(obj, timesteps, values)
        
            splined_obj = copy(obj);
            splined_obj.Values = [timesteps', values];
        end
        
    end
    
    methods (Static)
        
        function [values, labels, header] = load(filename)
        
            data_array = importdata(filename);
            values = data_array.data;
            labels = data_array.colheaders;
            header = data_array.textdata(1:end - 1, 1);
        
        end
        
        function [values, labels, header] = parse(filename)
        
            [values, labels, header] = MOTSTOData.load(filename);
        
        end
    
    end

end