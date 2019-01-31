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

end