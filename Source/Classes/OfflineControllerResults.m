classdef OfflineControllerResults
    % Class for storing the results of a run of the OfflineExOptController,
    %   including which optimisation scheme was used in the run. 
    
    properties (SetAccess = private)
        OfflineController
        OptimisationScheme
        MotorCommands
        ExoskeletonContribution
        HumanContribution
        StartTime
        EndTime
    end
    
    methods
        
        function obj = OfflineControllerResults(OfflineController, ...
                opt, results, startTime, endTime)
            obj.OfflineController = OfflineController;
            obj.OptimisationScheme = opt;
            obj.StartTime = startTime;
            obj.EndTime = endTime;
            exo_dofs = OfflineController.Exoskeleton.Exo_dofs;
            human_dofs = OfflineController.Exoskeleton.Human_dofs;
            obj.MotorCommands = results(1:exo_dofs);
            obj.ExoskeletonContribution = results(...
                exo_dofs + 1:exo_dofs + human_dofs);
            obj.HumanContribution = results(...
                exo_dofs + human_dofs + 1:end);
        end
        
    end
    
end

