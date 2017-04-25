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
        
        function OfflineResult = runOptimisation(...
                obj,identifier, load, startTime, endTime)
            % First calculate the 
            ID = obj.processRawData(load, startTime, endTime);
            obj = obj.computeForceModel(RRA);
            obj = obj.advanceDesired(ID);
            timesteps = size(ID.Timesteps,2);
            results = zeros(timesteps,1);
            for i=1:timesteps
                if strcmp(identifier, 'LLSEE')
                    [A,b,C,d,E,f] = setupLLSEE(obj, startTime, endTime, ...
                        ID, i);
                    results(i,1:end) =  lsqlin(A,b,C,d,E,f);
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
            b = obj.Desired.Result.Values(index,1:end).'; % desired vector
            C = [];
            d = []; % NO JOINT LIMITS FOR NOW, COME BACK TO THIS!
            P = obj.ForceModel.P{index};
            Q = obj.ForceModel.Q{index};
            E = [zeros(n,k), eye(n), eye(n); -P, ones(n), zeros(n)];
            f = [ID.id.Values(index,1:end).'; Q];
        end
        
        function ID = processRawData(obj, load, startTime, endTime)
            % Perform RRA and ID given load type, startTime & endTime from
            % user. 
            RRA = obj.Trial.runRRA(load, startTime, endTime);
            
            % Remember that we create a new OpenSimTrial using the RRA
            % kinematics!
            dir = [obj.Trial.results_directory '/IDTrial'];
            IDTrial = OpenSimTrial(obj.Trial.model_path, ...
                RRA.positions_path, obj.Trial.grfs_path, ...
                dir);
            
            % NOTE: the - 0.002 here is due to the fact that RRA ends 2
            % timesteps before the given time. Obviously this is a bandaid
            % fix and I need to investigate the root of the problem - I'll
            % come back to this, have made a post it.
            ID = IDTrial.runID(load, startTime, endTime - 0.002);
        end
        
        function obj = computeForceModel(obj, RRA)
            dir = [obj.ResultsDirectory '/ForceModel'];
            obj.ForceModel = obj.Exoskeleton.constructExoskeletonForceModel(...
                RRA.states, dir, obj.ForceModelDescriptor);
        end
        
        function obj = advanceDesired(obj, ID)
            obj.Desired = obj.Desired.evaluateDesired(ID);
        end
        
    end
    
end

