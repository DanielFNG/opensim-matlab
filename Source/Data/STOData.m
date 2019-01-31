classdef STOData < OpenSimData
    
    properties
        Filetype = '.sto'
    end
    
    methods
    
        function obj = STOData(varargin)
        % Construct STOData from (file) or from (values, header, labels). 
            obj@OpenSimData(varargin{:});
        end
        
        % Updates header info to match the data object. Intended only to be
        % used as part of writeToFile function. 
        function updateHeader(obj)
            obj.Header{3} = ['nRows=' num2str(obj.NFrames)];
            obj.Header{4} = ['nColumns=' num2str(length(obj.Labels))];
        end
        
        function printLabels(obj, fileID) 
            MOTData.printLabels(obj, fileID)
        end
        
        function printValues(obj, fileID)
            MOTData.printValues(obj, fileID)
        end
        
    end
    
    methods (Static)
        
        function [values, labels, header] = load(filename)
        
            [values, labels, header] = MOTData.load(filename);
            
        end
        
        function [values, labels, header] = parse(filename)
            
            [values, labels, header] = MOTData.parse(filename);
            
        end
        
    end

end