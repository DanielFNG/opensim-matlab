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
        Exoskeleton % the exoskeleton to which this model relates
        States % time-indexed states of the human-exoskeleton model 
        P % cell array (even if only one element!) containing linear mult's.
        Q % cell array containing linear constants. 
    end
    
    methods
        
        function obj = LinearExoskeletonForceModel(exo, states, P, Q)
            % Name is an identifier and P, Q are cell arrays containing
            % indexed P, Q. Note: even if this is for a single timestep
            % i.e. working with only one P and one Q, still have to be
            % given as cell arrays!
            if nargin > 0
                if size(P,1) ~= size(Q,1) 
                    error('Size discrepancy in LinearExoskeletonForceModel.');
                end
                obj.Exoskeleton = exo;
                obj.States = states;
                obj.P = P;
                obj.Q = Q;
            end
        end    
        
    end
    
end

