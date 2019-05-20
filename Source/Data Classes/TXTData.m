classdef TXTData < MOTSTOTXTData
% Class for storing & working with OpenSim data in .txt format.

    properties (SetAccess = protected)
        Filetype = '.txt'
    end

    methods
        
        function obj = TXTData(varargin)
        % Construct TXTData from (file) or from (values, header, % labels).
            obj@MOTSTOTXTData(varargin{:});
        end
        
    end
    
    methods (Access = protected)
        
        function updateHeader(obj)
        % Update header info to match Data object.
            
        end
    
    end

end