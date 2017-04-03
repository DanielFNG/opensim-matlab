classdef RRAResults
    % Just a small class for holding the results of the RRA algorithm. 
    % At some point want to add functionality for automatically analysing
    % residuals to see if they're good enough. 
    
    properties (SetAccess = private)
        forces % Actuation forces 
        accelerations % Joint accelerations etc.
        velocities
        positions
        errors % Position error between desired & achieved kinematics. 
        states 
    end
    
    properties (GetAccess = private)
        % Store paths incase, might not need them, especially not if we
        % need to change the data i.e. subsampling or cutting off data
        % points.
        forces_path
        accelerations_path
        velocities_path
        positions_path
        errors_path
        states_path
    end
    
    methods
        
        % Construct RRAResults object from a directory where the files are
        % located, trialName gives the prefix to the files. 
        function obj = RRAResults(trialName, directory)
            if nargin > 0 
                directory = getFullPath(directory);
                obj.forces_path = ...
                    [directory '/' trialName '_Actuation_force.sto'];
                obj.accelerations_path = ...
                    [directory '/' trialName '_Kinematics_dudt.sto'];
                obj.velocities_path = ...
                    [directory '/' trialName '_Kinematics_u.sto'];
                obj.positions_path = ...
                    [directory '/' trialName '_Kinematics_q.sto'];
                obj.errors_path = ...
                    [directory '/' trialName '_pErr.sto'];
                obj.states_path = ...
                    [directory '/' trialName '_states.sto'];
                obj.forces = RRAData(obj.forces_path);
                obj.accelerations = RRAData(obj.accelerations_path);
                obj.velocities = RRAData(obj.velocities_path);
                obj.positions = RRAData(obj.positions_path);
                obj.errors = RRAData(obj.errors_path);
                obj.states = RRAData(obj.states_path);
            end
        end
        
    end
    
end

