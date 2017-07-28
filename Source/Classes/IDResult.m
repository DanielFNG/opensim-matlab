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
        
        % Return the vector of torques at a given time index. This is
        % returned as a column vector, and has no time entry. This is used
        % during the optimisation. 
        function input_vector = getVector(obj, index)
            input_vector = obj.id.Values(index,2:end).';
        end
        
    end
    
end

