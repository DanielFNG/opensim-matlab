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
            
            % Load the dofs for the human and exoskeleton models.
            [n, k] = obj.loadDegreesOfFreedom();
            
            % Construct a results array of the correct size for the number
            % of frames and optimisation variables.
            results = zeros(obj.Frames, 2*obj.HumanDOFS + obj.ExoDOFS);
            
            % Construct the inequality constraints from the exoskeleton
            % torque limits.
            [C, d] = obj.setupTorqueLimits();
            
            % If the identifer is HQP, setup an array to hold the slack results,
            % then setup and run the optimisation. If it's not, try to run
            % setup for one of the LLS methods. 
            if strcmp(identifier, 'HQP')
                % Setup array to hold slack variable results.
                slack_variables = 2; % Need 2 slack variables currently. 
                slack = zeros(slack_variables, obj.Frames, obj.HumanDOFS);
                
                % Solve the optimisation problem at each frame.
                for i=1:obj.Frames
                    % Get access to the force model parameters.
                    [P, Q] = obj.getForceModelParameters(i);
                    
                    % Set up and run optimisation.
                    [results(i,1:end), slack(1:end,i,1:end)]  = ...
                        obj.setupAndRunHQP(i, n, k, C, d, P, Q);
                end
                
                % Process results.
                OptResult = OptimisationResult(obj, identifier, results, slack);
            else
                % Solve the optimisation problem at each frame.
                for i=1:obj.Frames
                    % Get access to the force model parameters.
                    [P, Q] = obj.getForceModelParameters(i);
                    
                    % Setup and run optimisation.
                    [A,b,E,f] = ...
                        obj.setupOptimisation(identifier, i, n, k, P, Q);
                    results(i,1:end) = ...
                        obj.runOptimisation(identifier,A,b,C,d,E,f);
                end
                
                % Process results. 
                OptResult = OptimisationResult(obj, identifier, results);
            end
            % Note: thought it better to have two loops rather than a check
            % for the identifier in every loop. 
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
                zeros(n,k), zeros(n), obj.DesiredTorques.CoefficientMatrix];
            b = [obj.InputTorques.getVector(index); ...
                Q ; ...
                obj.DesiredTorques.getDesiredVector(index)];
           
        end
        
        function [A,b,E,f] = setupLLSE(obj, index, n, k, P, Q)
            % Construct equality constraints.
            E = [zeros(n,k), eye(n), eye(n)];
            f = obj.InputTorques.getVector(index);
            
            % Construct system to solve.
            A = [-P, eye(n), zeros(n); ...
                zeros(n,k), zeros(n), obj.DesiredTorques.CoefficientMatrix];
            b = [Q ; obj.DesiredTorques.getDesiredVector(index)];
        end
        
        function [A,b,E,f] = setupLLSEE(obj, index, n, k, P, Q)
            % Construct equality constraints.
            E = [zeros(n,k), eye(n), eye(n); -P, eye(n), zeros(n)];
            f = [obj.InputTorques.getVector(index); Q];
            
            % Construct system to solve.
            A = [zeros(n,k), zeros(n), obj.DesiredTorques.CoefficientMatrix]; 
            b = obj.DesiredTorques.getDesiredVector(index); % desired         
        end
        
        function [results, slack] = setupAndRunHQP(obj, index, n, k, C, d, P, Q)
            % Initialise the slack array. Hard-coded as 3 slack variables
            % now... better way of doing this though... 
            slack = zeros(2,n);
            
            % Append zero-matrices of size n on to the inequality
            % constraint matrix to account for the slack variable at each
            % step.
            C = [C, zeros(2*k,n)];
            
            % The objective function is eqivalent to minimising the squared
            % error in the slack variable. The slack variable joints the
            % usual optimisation variable set, at the end, and is 23
            % dimensional. 
            H = 2*[zeros(2*n + k), zeros(2*n + k, n); ...
                zeros(n, 2*n + k), eye(n)];
            f = [];
            
            % Setup first QP level. Equality constraint now adds the force
            % model.
            A = [zeros(n,k), eye(n), eye(n), zeros(n); ...
                -P, eye(n), zeros(n), -eye(n)];
            b = [obj.InputTorques.getVector(index); Q];
            
            % Solve first QP level.
            full_results = quadprog(H,f,C,d,A,b);
            
            % Save the first slack variable.
            slack(1,1:end) = full_results(k + 2*n + 1:end);
            
            % Setup second QP level. Now includes desired. 
            A = [zeros(n,k), eye(n), eye(n), zeros(n); ...
                -P, eye(n), zeros(n), zeros(n); ...
                zeros(n,k), zeros(n), obj.DesiredTorques.CoefficientMatrix, -eye(n)];
            b = [obj.InputTorques.getVector(index); ...
                Q + slack(1,1:end).'; ...
                obj.DesiredTorques.getDesiredVector(index)];
            
            % Solve second QP level.
            full_results = quadprog(H,f,C,d,A,b);
            
            % Save the second slack variable.
            slack(2,1:end) = full_results(k + 2*n + 1:end);
            
            % Save the final, overall results.
            results = full_results(1:k + 2*n);
            
        end
        
    end
    
    methods (Access = private, Static)
        
        % Given the optimisation parameters and an identifier, run the
        % optimisation. 
        function results = runOptimisation(identifier, A, b, C, d, E, f)
            if strcmp(identifier, 'LLS') || strcmp (identifier, 'LLSE') || ...
                    strcmp(identifier, 'LLSEE')
                results = lsqlin(A,b,C,d,E,f);
            else
                error('Specified optimisation method not recognised.');
            end
        end
        
    end
end

