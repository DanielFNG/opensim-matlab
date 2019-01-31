classdef MOTData < OpenSimData

    properties
        Filetype = '.mot' 
    end
    
    methods
    
        function obj = MOTData(varargin)
        % Construct MOTData from (file) or from (values, header, labels). 
            obj@OpenSimData(varargin{:});
        end
        
        % Updates header info to match the data object. Intended only to be
        % used as part of writeToFile function. 
        function updateHeader(obj)
            obj.Header{2} = ['datacolumns ' num2str(length(obj.Labels))];
            obj.Header{3} = ['datarows ' num2str(size(obj.Values, 1))];
            obj.Header{4} = ['range ' num2str(obj.Timesteps(1)) ' ' ...
                num2str(obj.Timesteps(end))];
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
                    fprintf(fileID,'%12.14f\t', obj.Values(i,j));
                end
                fprintf(fileID,'\n');
            end
        
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
        
            [values, labels, header] = MOTData.load(filename);
        
        end
    
    end

end