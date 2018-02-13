classdef RRAResults
    % Just a small class for holding the results of the RRA algorithm. 
    % At some point want to add functionality for automatically analysing
    % residuals to see if they're good enough. 
    
    properties (SetAccess = private)
        OpenSimTrial % The OST to which this RRAResult is associated. 
        start % first timestep
        final % last timestep
        forces % Actuation forces 
        accelerations % Joint accelerations etc.
        velocities
        positions
        errors % Position error between desired & achieved kinematics. 
        states
        
        Residuals % Class for storing residual results. 
        Grade % Whether residuals are all okay or not. 
        
        forces_path
        accelerations_path
        velocities_path
        positions_path
        errors_path
        states_path
    end
    
    properties (SetAccess = private, GetAccess = private)
        Adjustment = false
        AdjustedModel = 'N/A'
    end
    
    methods
        
        % Construct RRAResults object from a directory where the files are
        % located, trialName gives the prefix to the files. 
        function obj = RRAResults(OpenSimTrial, directory, model)
            if nargin > 0
                if nargin == 3
                    obj.Adjustment = true; 
                    obj.AdjustedModel = model;
                end
                obj.OpenSimTrial = OpenSimTrial;
                obj.forces_path = ...
                    [directory '_Actuation_force.sto'];
                obj.accelerations_path = ...
                    [directory '_Kinematics_dudt.sto'];
                obj.velocities_path = ...
                    [directory '_Kinematics_u.sto'];
                obj.positions_path = ...
                    [directory '_Kinematics_q.sto'];
                obj.errors_path = ...
                    [directory '_pErr.sto'];
                obj.states_path = ...
                    [directory '_states.sto'];
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
                
                % Analyse the RRA residuals.
                obj = obj.analyseResiduals();
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
        
        function model = getAdjustedModel(obj)
            % Return the full path of the adjusted model associated with
            % this RRA result. Throw an error if this RRAResult is not
            % associated with an adjusted model. 
            if ~ obj.Adjustment 
                error('This RRAResult was obtained without adjustment.');
            end
            model = obj.AdjustedModel;
        end
        
        % Compute the RRA thresholds for this RRAResult.
        function obj = analyseResiduals(obj)
            obj.Residuals = RRAResiduals(obj);
            obj.Grade = obj.Residuals.getTotalGrade();
        end
        
    end
    
end

