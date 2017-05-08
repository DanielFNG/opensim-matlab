classdef OfflineController
    % Offline ExOpt controller. 
    % Takes experimental input data/model, and an
    % exoskeleton, & uses optimisation to compute the
    % exoskeleton motor commands which will best match a desired human
    % contribution to the net torque trajectory.
    
    properties (SetAccess = private)
        Trial
        Exoskeleton
        ForceModelDescriptor
        ForceModel
        Desired
        ResultsDirectory
    end
    
    methods
        
        function obj = OfflineController(OpenSimTrial, ...
                    Exoskeleton, ForceModel, Desired, dir)
                % ForceModel is a string descriptor for the force model
                % used e.g. 'linear'.
            if nargin == 5 
                obj.Trial = OpenSimTrial;
                obj.Exoskeleton = Exoskeleton;
                obj.ForceModelDescriptor = ForceModel;
                obj.Desired = Desired;
                obj.ResultsDirectory = dir;
            elseif nargin ~= 0
                error('OfflineExOptController requires 0 or 5 arguments.');
            end
        end
        
        % Change this to just .run() then use the new Optimisation class
        % within. 
        function [OfflineResult, obj] = run(obj,identifier, startTime, endTime)
            % First process the raw data, compute the force model
            % parameters and advance the desired.
            [RRA, ID] = obj.processRawData(startTime, endTime);
            obj = obj.computeForceModel(RRA);
            obj = obj.advanceDesired(ID);
            
            % Set up the optimisation and solve it using the given method.
            opt = Optimisation(ID, obj.Desired, obj.ForceModel);
            OptResult = opt.run(identifier);
            
            % Store the overall results as an OfflineResult. 
            OfflineResult = OfflineControllerResults(...
                    obj, identifier, OptResult, startTime, endTime);
        end
        
    end
    
    methods (Access = private)
        
        function [RRA, ID] = processRawData(obj, startTime, endTime)
            % Perform RRA and ID given startTime & endTime from user. 
            RRA = obj.Trial.runRRA(startTime, endTime);
            
            % Remember that we create a new OpenSimTrial using the RRA
            % kinematics!
            dir = [obj.Trial.results_directory '/IDTrial'];
            IDTrial = OpenSimTrial(obj.Trial.model_path, ...
                RRA.positions_path, obj.Trial.load, obj.Trial.grfs_path, ...
                dir);
            
            ID = IDTrial.runID(startTime, endTime);
        end
        
        function obj = computeForceModel(obj, RRA)
            dir = [obj.ResultsDirectory '/ForceModel'];
            obj.ForceModel = obj.Exoskeleton.constructExoskeletonForceModel(...
                RRA, dir, obj.ForceModelDescriptor);
        end
        
        function obj = advanceDesired(obj, ID)
            obj.Desired = obj.Desired.evaluateDesired(ID);
        end
        
    end
    
end

