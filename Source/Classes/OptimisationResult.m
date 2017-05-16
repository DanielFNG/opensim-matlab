classdef OptimisationResult
    % Class to hold the results of an optimisation. 
    
    properties (SetAccess = private)
        Optimisation
        OptimisationScheme
        MotorCommands
        ExoskeletonContribution
        HumanContribution
    end
    
    methods
        
        function obj = OptimisationResult(Optimisation, identifier, results)
            obj.Optimisation = Optimisation;
            obj.OptimisationScheme = identifier;
            exo_dofs = Optimisation.ExoDOFS;
            human_dofs = Optimisation.HumanDOFS;
            obj.MotorCommands = results(1:end,1:exo_dofs);
            obj.ExoskeletonContribution = results(1:end,...
                exo_dofs + 1:exo_dofs + human_dofs);
            obj.HumanContribution = results(1:end,...
                exo_dofs + human_dofs + 1:end);
        end
        
    end
    
end

