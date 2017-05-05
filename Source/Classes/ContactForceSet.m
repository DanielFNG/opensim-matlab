classdef ContactForceSet
    % Class for storing spatial forces at the Exoskeleton contact
    % points. 
    
    properties (SetAccess = private) 
        Model % Model file
        States % States file
        Names % array of names given to the contact points in the setup file
        ForceSet % set of spatial forces. Character array {timesteps, contact}.
        MotorTorqueProfile = 'Unit' % array giving motor torque profiles 
        % If no motor torque profile is given it's assumed these are unit 
        % spatial forces e.g. for use in optimisation. 
    end
    
    methods
        
        function obj = ContactForceSet(FrameJacobianSet, ForceSet, Motors)
            if nargin > 0
                obj.Model = FrameJacobianSet.Model;
                obj.States = FrameJacobianSet.States;
                obj.Names = FrameJacobianSet.Names;
                obj.ForceSet = ForceSet;
                if nargin == 3
                    obj.MotorTorqueProfile = Motors; 
                end
            end
        end
        
    end
    
end

