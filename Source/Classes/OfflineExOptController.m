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
            obj.ExoskeletonForceModel = ExoskeletonForceModel;
            obj.Desired = Desired;
        end
        
        function result = runOptimisation(obj,identifier, startTime, endTime)
            if strcmp(identifier, 'LLSEE')
                [A,b,C,d,E,f] = setupLLSEE(obj, startTime, endTime);
                result = runLLSEE(A,b,C,d,E,f);
            else 
                error('Specified optimisation method not recognized.');
            end
        end
        
        function [A,b,C,d,E,f] = setupLLSEE(obj, startTime, endTime)
            
        end
        
    end
    
end

