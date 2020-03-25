classdef STOData < MOTSTOTXTData
% Class for storing & working with OpenSim data in .sto format.
    
    properties (SetAccess = protected)
        Filetype = '.sto'
    end
    
    methods
    
        function obj = STOData(varargin)
        % Construct STOData from (file) or from (values, header, labels). 
            obj@MOTSTOTXTData(varargin{:});
        end
        
    end
    
    methods (Access = protected)
        
        function updateHeader(obj)
        % Update header info to match Data object. 
            obj.Header{3} = ['nRows=' num2str(obj.NFrames)];
            obj.Header{4} = ['nColumns=' num2str(length(obj.Labels))];
        end
        
        function setTimeLabel(obj)
            obj.TimeLabel = 'time';
        end
        
    end

end