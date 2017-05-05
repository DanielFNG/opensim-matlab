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
        RRA % an RRAResult, to give access to the underlying OST
        States % time-indexed states of the human-exoskeleton model
        P % cell array (even if only one element!) containing linear mult's.
        Q % cell array containing linear constants.
        FrameJacobians % FrameJacobianSet 
        ContactForces % ContactForceSet 
    end
        
    methods
        
        function obj = LinearExoskeletonForceModel(exo, rra, P, Q, ...
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
                obj.RRA = rra;
                obj.States = rra.states;
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
        
        % Write the spatial forces contained in a spatialForceSet to file
        % alongside the existing external forces, so that they can be used in 
        % an OpenSim simulation. For the purposes of getting my first year
        % review done on time, I'm going to write this up for the APO only.
        % But it shouldn't be too difficult to make it general as a
        % function of the exoskeleton settings file. Basically this entire
        % function is terrible and fudged right now. Come back to this when
        % you have more time. 
        function [ext, apo_only] = ...
                createExtForcesFileAPOSpecific(obj, spatialForceSet)
            % Make the labels.
            labels = {'time',...
                'apo_force_vx','apo_force_vy','apo_force_vz',...
                'apo_force_px','apo_force_py','apo_force_pz',...
                '1_apo_force_vx','1_apo_force_vy','1_apo_force_vz',...
                '1_apo_force_px','1_apo_force_py','1_apo_force_pz',...
                'apo_group_force_vx','apo_group_force_vy','apo_group_force_vz',...
                'apo_group_force_px','apo_group_force_py','apo_group_force_pz',...
                '1_apo_group_force_vx','1_apo_group_force_vy','1_apo_group_force_vz',...
                '1_apo_group_force_px','1_apo_group_force_py','1_apo_group_force_pz'};
            
            % Arrange the spatialForceSet in to a convenient form (a
            % Matrix). Only the FX and FY components are non-zero, we still
            % need to include the FZ as 0's but we can ignore the M's.
            n_timesteps = size(spatialForceSet.ForceSet,1);
            n_forces = size(spatialForceSet.ForceSet,2);
            values = zeros(n_timesteps,6*n_forces+1);
            for i=1:n_timesteps
                b = 0;
                k = 2;
                for j=1:n_forces
                        values(i,k+b) = spatialForceSet.ForceSet{i,j}(4);
                        values(i,k+1+b) = spatialForceSet.ForceSet{i,j}(5);
                        values(i,k+2+b) = spatialForceSet.ForceSet{i,j}(6);
                        k = k + 3;
                        b = b + 3;
                end
            end
            values(1:end,1) = spatialForceSet.States.Timesteps(1:end,1);
            
            % Now add the centre of pressure columns. This is hard coded
            % but in practice could and should be read from the Exoskeleton
            % settings file (either now or possibly at the start and saved
            % when 'loading' the Exoskeleton - makes more sense.
            % LoadSettingsFromFile or something.
            for i=1:n_timesteps
                values(i,5) = 0;
                values(i,6) = 0.23;
                values(i,7) = 0.09;
                
                values(i,11) = 0;
                values(i,12) = 0.23; 
                values(i,13) = -0.09;
                
                values(i,17) = -0.116587;
                values(i,18) = 0.0999654;
                values(i,19) = -0.153457;
                
                values(i,23) = -0.116587;
                values(i,24) = 0.0999654;
                values(i,25) = 0.153457;
            end
            
            % Create an empty data object then assign these labels and
            % values. 
            apo_only = Data();
            apo_only.Values = values;
            apo_only.Labels = labels;
            apo_only.Timesteps = spatialForceSet.States.Timesteps;
            apo_only.isTimeSeries = true;
            apo_only.Header = obj.RRA.OpenSimTrial.grfs.Header;
            apo_only.hasHeader = true;
            apo_only.isLabelled = true;
            apo_only = apo_only.updateHeader();
            
            % Fit both this data and the input grf data to 1000Hz. 
            new_grfs = obj.RRA.OpenSimTrial.grfs.fitToSpline(1000);
            apo_only = apo_only.fitToSpline(1000);
            
            % Align the start and end points of the data. 
            [new_grfs, apo_only, ~, ~] = new_grfs.alignData(apo_only);
            
            % Add these together.
            ext = new_grfs + apo_only;
        end
        
    end
    
end

