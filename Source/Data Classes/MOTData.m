classdef MOTData < MOTSTOTXTData
% Class for storing & working with OpenSim Data in .mot format.
    
    properties (SetAccess = protected)
        Filetype = '.mot'
    end
    
    methods
    
        function obj = MOTData(varargin)
        % Construct MOTData from (file) or from (values, header, labels). 
            obj@MOTSTOTXTData(varargin{:});
        end
        
    end
    
    methods (Access = protected)
        
        function updateHeader(obj)
        % Updates header info to match Data object.
            obj.Header{2} = ['datacolumns ' num2str(length(obj.Labels))];
            obj.Header{3} = ['datarows ' num2str(size(obj.Values, 1))];
            obj.Header{4} = ['range ' num2str(obj.Timesteps(1)) ' ' ...
                num2str(obj.Timesteps(end))];
        end
        
        function setTimeLabel(obj)
            obj.TimeLabel = 'time';
        end
        
    end

end