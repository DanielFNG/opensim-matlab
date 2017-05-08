classdef OfflineControllerResults
    % Class for storing the results of a run of the OfflineExOptController,
    %   including which optimisation scheme was used in the run. 
    
    properties (SetAccess = private)
        OfflineController
        OptimisationScheme
        OptimisationResult
        StartTime
        EndTime
    end
    
    methods
        
        function obj = OfflineControllerResults(OfflineController, ...
                scheme, optresult, startTime, endTime)
            obj.OfflineController = OfflineController;
            obj.OptimisationScheme = scheme;
            obj.StartTime = startTime;
            obj.EndTime = endTime;
            obj.OptimisationResult = optresult;
        end
        
    end
    
end

