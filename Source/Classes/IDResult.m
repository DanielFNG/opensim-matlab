classdef IDResult
    % Just a small class for holding the results of using the OpenSim 
    % inverse dynamics tool. Tied to an OpenSimTrial. 
    
    properties (SetAccess = private)
        OpenSimTrial % The OST to which this RRA result is associated
        start % first timestep 
        final % last timestep 
        id % ID result stored as a data object. 
        id_path % Path to ID storage file. 
    end
    
    methods
        
        function obj = IDResult(OpenSimTrial, directory)
            if nargin > 0
                obj.OpenSimTrial = OpenSimTrial;
                directory = getFullPath(directory);
                obj.id_path = [directory 'id.sto'];
                obj.id = Data(obj.id_path);
                obj.start = obj.id.Timesteps(1);
                obj.final = obj.id.Timesteps(end);
            end
        end
        
    end
    
end

