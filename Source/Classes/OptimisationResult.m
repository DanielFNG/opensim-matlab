classdef OptimisationResult
    % Class to hold the results of an optimisation. 
    
    properties (SetAccess = private)
        Optimisation
        OptimisationScheme
        MotorCommands
        ExoskeletonContribution = 'N/A'
        HumanContribution
        Sparse
        Fast
        Slack = 'N/A'
    end
    
    methods
        
        function obj = OptimisationResult(Optimisation, identifier, ...
                results, sparse, fast, slack)
            if nargin > 0
                obj.Optimisation = Optimisation;
                obj.OptimisationScheme = identifier;
                exo_dofs = Optimisation.ExoDOFS;
                human_dofs = Optimisation.HumanDOFS;
                obj.Sparse = sparse;
                obj.Fast = fast;
                obj.MotorCommands = results(1:end,1:exo_dofs);
                if strcmp(identifier, 'QPOases')
                    obj.HumanContribution = results(1:end, ...
                        exo_dofs + 1:exo_dofs + human_dofs);
                    obj.Slack = results(1:end, exo_dofs + human_dofs + 1:end);
                else
                    obj.ExoskeletonContribution = results(1:end,...
                        exo_dofs + 1:exo_dofs + human_dofs);
                    obj.HumanContribution = results(1:end,...
                        exo_dofs + human_dofs + 1:end);
                    if nargin == 6
                        obj.Slack = slack;
                    end
                end
            end
        end
        
    end
    
end

