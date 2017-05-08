classdef Optimisation
    % A class for performing the optimisation. 
    % Support for different types of optimisation methods should be added here.
    % Inputs are some input data in the form of an IDResult, an
    % exoskeleton force model (i.e. P and Q evaluated), and a desired human 
    % contribution. These inputs should have the same number of frames. The 
    % output is an OptimisationResult, which stores the resulting set of 
    % optimisation variables over the frames provided. 
    
    properties (SetAccess = private)
        InputTorques
        DesiredTorques
        ForceModel
        HumanDOFS
        ExoDOFS
    end
    
    properties (SetAccess = private, GetAccess = private)
        Frames
    end
    
    methods
        
        function obj = Optimisation(id, des, model)
            if nargin > 0
                % Check that each input is of the correct type.
                if ~isa(id, 'IDResult')
                    error('Input torques must be given as an IDResult.');
                elseif ~isa(des, 'Desired')
                    error('Desired torques must be given as a Desired.');
                elseif ~isa(model, 'LinearExoskeletonForceModel')
                    error('model should be a LinearExoskeletonForceModel');
                end
                
                % Check that the inputs have the same number of frames. The 
                % desired will be based off the input id so only need to
                % check the input id and the force model. 
                if id.id.Frames ~= model.States.Frames
                    error(['The input ID and the exoskeleton force model'...
                        ' do not share the same number of frames.']);
                end
                obj.Frames = model.States.Frames;
                obj.HumanDOFS = id.OpenSimTrial.human_dofs;
                obj.ExoDOFS = model.Exoskeleton.Exo_dofs;
                obj.InputTorques = id;
                obj.DesiredTorques = des.evaluateDesired(id);
                obj.ForceModel = model; 
            end
        end
        
        % Perform the optimisation.
            % Identifier should identify which optimisation method to use.
                if strcmp(identifier, 'LLSEE')
                    [A,b,C,d,E,f] = obj.setupLLSEE(i);
                    results(i,1:end) = lsqlin(A,b,C,d,E,f);
                else
                    error('Specified optimisation method not recognised.');
                end
            end
            OptResult = OptimisationResult(obj, identifier, results);
        end
        
    end
    
    methods (Access = private)
        
        function [A,b,C,d,E,f] = setupLLSEE(obj, index)
            n = obj.HumanDOFS;
            k = obj.ExoDOFS;  
            A = [zeros(n,k), zeros(n), eye(n)]; % coefficient matrix
            b = obj.DesiredTorques.Result.Values(index,2:end).'; % desired
            % Note going from 2:end is to miss out the time bit!
            C = [];
            d = []; % NO JOINT LIMITS FOR NOW, COME BACK TO THIS!
            P = obj.ForceModel.P{index};
            Q = obj.ForceModel.Q{index};
            E = [zeros(n,k), eye(n), eye(n); -P, eye(n), zeros(n)];
            f = [obj.InputTorques.id.Values(index,2:end).'; Q];
        end
        
    end
    
end

