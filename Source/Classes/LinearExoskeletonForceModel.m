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
    
    properties
        name % name of the exoskeleton, just for information
        P % cell array (even if only one element!) containing linear mult's.
        Q % cell array containing linear constants. 
    end
    
    methods
        
        function obj = LinearExoskeletonForceModel(name, P, Q)
            % Name is an identifier and P, Q are cell arrays containing
            % indexed P, Q. Note: even if this is for a single timestep
            % i.e. working with only one P and one Q, still have to be
            % given as cell arrays!
            if nargin > 0
                if size(P,1) ~= size(Q,1) 
                    error('Size discrepancy in LinearExoskeletonForceModel.');
                end
                obj.name = name;
                obj.P = P;
                obj.Q = Q;
            end
        end    
        
    end
    
    methods (Static)
        
        % Construct the current working version of the linear APO force
        % model given state information - Jacobians are calculated first.
        function APO_model = constructLinearAPOForceModel(OpenSimTrial, dir, d)
            % An OpenSimTrial, a directory where results should be stored.
            % The name of the APO will be hard coded given this is a
            % specific funtion for the APO. The parameter d is the link
            % length - or, where the APO force is modelled as being applied
            % on the link.
            Jacobians = FrameJacobianSet(OpenSimTrial, 'apo_old', dir);
            % IMPORTANT: using 'apo_old' for now for testing - later will
            % need to be updated! ALSO: not including the pelvis rotation
            % bit, only for the purposes of testing against the old
            % implementation. Then I'll reimplement this.
            nTimesteps = size(OpenSimTrial.rra.states.Timesteps,1);
            Q = 0;
            P{nTimesteps} = 0;
            right_hip_flexion = OpenSimTrial.rra.states. ...
                getDataCorrespondingToLabel('hip_flexion_r');
            left_hip_flexion = OpenSimTrial.rra.states. ...
                getDataCorrespondingToLabel('hip_flexion_l');
            for i=1:nTimesteps
                unit_right_force = [0;0;0; ...
                    cos(right_hip_flexion(i,1));sin(right_hip_flexion(i,1));0];
                unit_left_force = [0;0;0; ...
                    cos(left_hip_flexion(i,1));sin(left_hip_flexion(i,1));0];
                right_jacobian = Jacobians.JacobianSet{1}.Jacobian.Values{i};
                left_jacobian = Jacobians.JacobianSet{2}.Jacobian.Values{i};
                P{i} = 1/d*[right_jacobian.' * unit_right_force ...
                    , left_jacobian.' * unit_left_force];
            end
            APO_model = LinearExoskeletonForceModel('APO',P,Q);
        end
        
        function model = constructLinearExosksletonForceModel(...
                OpenSimTrial, dir, identifier)
            if strcmp(identifier, 'APO')
                d = 0.35; % Hard-coding d for now. 
                model = constructLinearAPOForceModel(OpenSimTrial, dir, d);
            else
                error('Unrecognized exoskeleton identifier.');
            end
        end
       
    end
    
end

