classdef OfflineExOptController
    % Offline ExOpt controller. Takes experimental input data/model, and an
    % exoskeleton force model, & uses optimisation to compute the
    % exoskeleton motor commands which will best match a desired human
    % contribution to the net torque trajectory.
    
    properties (SetAccess = private)
        OpenSimTrial
        ExoskeletonForceModel
        Desired
    end
    
    methods
        
        function obj = OfflineExOptController(OpenSimTrial, ...
                    ExoskeletonForceModel, Desired)
            obj.OpenSimTrial = OpenSimTrial;
        end
        
    end
    
end

