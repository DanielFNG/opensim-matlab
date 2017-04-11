classdef RRAResults
    % Just a small class for holding the results of the RRA algorithm. 
    % At some point want to add functionality for automatically analysing
    % residuals to see if they're good enough. 
    
    properties (SetAccess = private)
        start % first timestep
        final % last timestep
        forces % Actuation forces 
        accelerations % Joint accelerations etc.
        velocities
        positions
        errors % Position error between desired & achieved kinematics. 
        states
        
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
                obj.start = obj.forces.Timesteps(1);
                obj.final = obj.forces.Timesteps(end);
                
                % Rewrite RRA data files to account for intermediate
                % timestep removal.
                obj.rewriteRRA();
            end
        end
        
        % Rewrites the RRA files after reading them in.
        function rewriteRRA(obj)
            % A key feature of the RRAData class is that removes
            % intermediate RRA timesteps. We require the use of RRA data
            % later on in getJointSpaceForces and getFrameJacobians, and
            % I've already made the mistake once of forgetting to reprint
            % the RRA data to file post these changes. Therefore, I'm going
            % to make it an intrinsic part of getting RRA data - the
            % intermediate timesteps are removed, and the files are
            % reprinted. 
            obj.forces.writeToFile(obj.forces_path,1,1);
            obj.accelerations.writeToFile(obj.accelerations_path,1,1);
            obj.velocities.writeToFile(obj.velocities_path,1,1);
            obj.positions.writeToFile(obj.positions_path,1,1);
            obj.errors.writeToFile(obj.errors_path,1,1);
            obj.states.writeToFile(obj.states_path,1,1);
        end
        
    end
    
end

