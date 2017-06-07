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
        function OptResult = run(obj, identifier)
            % Identifier should identify which optimisation method to use.
            
            % Construct a results array of the correct size for the number
            % of frames and optimisation variables.
            results = zeros(obj.Frames, 2*obj.HumanDOFS + obj.ExoDOFS);
            
            % Load the dofs for the human and exoskeleton models.
            [n, k] = obj.loadDegreesOfFreedom();
            
            % Solve the optimisation problem at each frame.
            for i=1:obj.Frames
                % Construct the inequality constraints from the exoskeleton
                % torque limits.
                [C, d] = obj.setupTorqueLimits();
                
                % Get access to the force model parameters.
                [P, Q] = obj.getForceModelParameters(i);
                
                % Set up and run optimisation. 
                [A,b,E,f] = obj.setupOptimisation(identifier, i, n, k, P, Q);
                results(i,1:end) = obj.runOptimisation(identifier,A,b,C,d,E,f);
            end
            
            % Process results as an OptimisationResult. 
            OptResult = OptimisationResult(obj, identifier, results);
        end
        
    end
    
    methods (Access = private)
        
        function [A,b,E,f] = setupOptimisation(obj, identifier, index, n, k, P, Q)
            if strcmp(identifier, 'LLSEE')
                [A,b,E,f] = obj.setupLLSEE(index, n, k, P, Q);
            elseif strcmp(identifier, 'LLS')
                [A,b,E,f] = obj.setupLLS(index, n, k, P, Q);
            elseif strcmp(identifier, 'LLSE')
                [A,b,E,f] = obj.setupLLSE(index, n, k, P, Q);
            elseif strcmp(identifier, 'HQP')
                [A,b,E,f] = obj.setupHQP(index, n, k, P, Q);
            else
                error('Specified optimisation method not recognised.');
            end
        end
        
        function [n,k] = loadDegreesOfFreedom(obj)
            n = obj.HumanDOFS;
            k = obj.ExoDOFS;
        end
        
        function [P,Q] = getForceModelParameters(obj, index)
            P = obj.ForceModel.P{index};
            Q = obj.ForceModel.Q{index};
        end
        
        function [C,d] = setupTorqueLimits(obj)
            % Load dofs.
            [n, k] = obj.loadDegreesOfFreedom();
            
            % Inequality matrix.
            C = [eye(k), zeros(k,n) zeros(k,n);...
                -eye(k), zeros(k,n), zeros(k,n)];
            
            % For now this is hard coded for the APO.
            d = [15; 15; 15; 15];
        end
        
        function [A,b,E,f] = setupLLS(obj, index, n, k, P, Q)
            % Construct equality constraints. None for LLS. 
            E = [];
            f = [];
            
            % Construct system to solve.
            A = [zeros(n,k), eye(n), eye(n);
                -P, eye(n), zeros(n);
                zeros(n,k), zeros(n), eye(n)];
            b = [obj.InputTorques.getVector(index); Q ; ...
                obj.DesiredTorques.getDesiredVector(index)];
           
        end
        
        function [A,b,E,f] = setupLLSE(obj, index, n, k, P, Q)
            % Construct equality constraints.
            E = [zeros(n,k), eye(n), eye(n)];
            f = obj.InputTorques.getVector(index);
            
            % Construct system to solve.
            A = [-P, eye(n), zeros(n); zeros(n,k), zeros(n), eye(n)];
            b = [Q ; obj.DesiredTorques.getDesiredVector(index)];
        end
        
        function [A,b,E,f] = setupLLSEE(obj, index, n, k, P, Q)
            % Construct equality constraints.
            E = [zeros(n,k), eye(n), eye(n); -P, eye(n), zeros(n)];
            f = [obj.InputTorques.getVector(index); Q];
            
            % Construct system to solve.
            A = [zeros(n,k), zeros(n), eye(n)]; % coefficient matrix
            b = obj.DesiredTorques.getDesiredVector(index); % desired         
        end
    end
    
    methods (Access = private, Static)
        
        % Given the optimisation parameters and an identifier, run the
        % optimisation. 
        function results = runOptimisation(identifier, A, b, C, d, E, f)
            if strcmp(identifier, 'LLS') || strcmp (identifier, 'LLSE') || ...
                    strcmp(identifier, 'LLSEE')
                results = lsqlin(A,b,C,d,E,f);
            elseif strcmp(identifier, 'HQP')
                % Do HQP.
            else
                error('Specified optimisation method not recognised.');
            end
        end
        
    end
end

