classdef LinearExoskeletonForceModel
    % A class describing a linear exoskeleton force model as outlined in my
    % first year review.
    %
    % t_exo = P * A_exo + Q
    %
    % Mainly this class just holds P & Q.
    %
    % The class contains hard-coded functions for calculating the force
    % models for specific Exoskeletons given a unique identifier (their
    % name). 
    
    properties (SetAccess = private)
        Exoskeleton % the exoskeleton to which this model relates
        States % time-indexed states of the human-exoskeleton model
        P % cell array (even if only one element!) containing linear mult's.
        Q % cell array containing linear constants.
        FrameJacobians % FrameJacobianSet 
        ContactForces % ContactForceSet 
    end
        
    methods
        
        function obj = LinearExoskeletonForceModel(exo, states, P, Q, ...
                Jacobians, Forces)
            % Name is an identifier and P, Q are cell arrays containing
            % indexed P, Q. Note: even if this is for a single timestep
            % i.e. working with only one P and one Q, still have to be
            % given as cell arrays!
            if nargin > 0
                if size(P{1},1) ~= size(Q{1},1) 
                    error('Size discrepancy in LinearExoskeletonForceModel.');
                end
                obj.Exoskeleton = exo;
                obj.States = states;
                obj.P = P;
                obj.Q = Q;
                obj.FrameJacobians = Jacobians;
                obj.ContactForces = Forces;
            end
        end    
        
        function spatialForcesSet = ...
                calculateSpatialForcesFromTorqueTrajectory(obj, MotorTorques)
            % MotorTorques should be an array with nColumns equal to the number
            % of motors of the exoskeleton, and an arbitrary number of 
            % rows. The trajectory defined by each column is interpolated to 
            % be the same size as the ContactForces (i.e. the numer of 
            % timesteps in States). So it will be more accurate with more rows.
            
            % Check that you have a trajectory for each motor.
            nTrajectories = size(MotorTorques,2);
            if nTrajectories ~= obj.Exoskeleton.Exo_dofs
                error('Size error.');
            end
            
            % Rescale the trajectories.
            desiredRows = size(obj.States.Timesteps,1);
            scaledMotorTorques = zeros(desiredRows,nTrajectories); % preallocate
            for i=1:nTrajectories
                scaledMotorTorques(1:end,i) = stretchVector(...
                    MotorTorques(1:end,i), desiredRows);
            end
            
            % Calculate the spatial forces resulting from the scaled motor
            % torque trajectories.
            spatialForces{desiredRows, nTrajectories} = 0; % preallocate
            for i=1:desiredRows
                spatialForces{i,1} = ... 
                    scaledMotorTorques(i,1) ... % right motor 
                    * obj.ContactForces.ForceSet{i,1};
                spatialForces{i,2} = ...
                    scaledMotorTorques(i,2) ... % left motor 
                    * obj.ContactForces.ForceSet{i,2};
                spatialForces{i,3} = ...
                    scaledMotorTorques(i,1) ...
                    * obj.ContactForces.ForceSet{i,3};
                spatialForces{i,4} = ...
                    scaledMotorTorques(i,2) ...
                    * obj.ContactForces.ForceSet{i,4};
            end
            spatialForcesSet = ContactForceSet(obj.FrameJacobians, ...
                spatialForces, scaledMotorTorques);
        end
        
    end
    
end

