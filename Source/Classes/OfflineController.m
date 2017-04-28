classdef OfflineController
    % Offline ExOpt controller. Takes experimental input data/model, and an
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
        
        function [OfflineResult, obj] = runOptimisation(...
                obj,identifier, startTime, endTime)
            % First calculate the 
            [RRA, ID] = obj.processRawData(startTime, endTime);
            obj = obj.computeForceModel(RRA);
            obj = obj.advanceDesired(ID);
            timesteps = size(ID.id.Timesteps,1);
            results = zeros(timesteps,2*obj.Exoskeleton.Human_dofs ...
                + obj.Exoskeleton.Exo_dofs);
            for i=1:timesteps-20 % somehow force model stops 20 timesteps b4
                if strcmp(identifier, 'LLSEE')
                    [A,b,C,d,E,f] = obj.setupLLSEE(ID, i);
                    results(i,1:end) =  lsqlin(A,b,C,d,E,f);
                    %x = lsqlin(A,b,C,d,E,f);
                    %results(i,1:end) = x(1:end,i);
                else 
                    error('Specified optimisation method not recognized.');
                end
            end
            OfflineResult = OfflineControllerResults(...
                    obj, identifier, results, startTime, endTime);
        end
        
        function [A,b,C,d,E,f] = setupLLSEE(obj, ID, index)
            n = obj.Exoskeleton.Human_dofs; % human degrees of freedom
            k = obj.Exoskeleton.Exo_dofs; % exoskeleton (active) dofs 
            A = [zeros(n,k), zeros(n), eye(n)]; % coefficient matrix
            b = obj.Desired.Result.Values(index,2:end).'; % desired vector
            % Note going from 2:end is to miss out the time bit!
            C = [];
            d = []; % NO JOINT LIMITS FOR NOW, COME BACK TO THIS!
            P = obj.ForceModel.P{index};
            Q = obj.ForceModel.Q{index};
            E = [zeros(n,k), eye(n), eye(n); -P, eye(n), zeros(n)];
            f = [ID.id.Values(index,2:end).'; Q];
        end
        
        function [RRA, ID] = processRawData(obj, startTime, endTime)
            % Perform RRA and ID given startTime & endTime from user. 
            RRA = obj.Trial.runRRA(startTime, endTime);
            
            % Remember that we create a new OpenSimTrial using the RRA
            % kinematics!
            dir = [obj.Trial.results_directory '/IDTrial'];
            IDTrial = OpenSimTrial(obj.Trial.model_path, ...
                RRA.positions_path, obj.Trial.load, obj.Trial.grfs_path, ...
                dir);
            
            % NOTE: the - 0.002 here is due to the fact that RRA ends 2
            % timesteps before the given time. Obviously this is a bandaid
            % fix and I need to investigate the root of the problem - I'll
            % come back to this, have made a post it.
            ID = IDTrial.runID(startTime, endTime - 0.002);
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

