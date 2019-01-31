classdef STOData < MOTSTOData
    
    properties
        Filetype = '.sto'
    end
    
    methods
    
        function obj = STOData(varargin)
        % Construct STOData from (file) or from (values, header, labels). 
            obj@MOTSTOData(varargin{:});
        end
        
        % Updates header info to match the data object. Intended only to be
        % used as part of writeToFile function. 
        function updateHeader(obj)
            obj.Header{3} = ['nRows=' num2str(obj.NFrames)];
            obj.Header{4} = ['nColumns=' num2str(length(obj.Labels))];
        end
        
    end

end