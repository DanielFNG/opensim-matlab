classdef JointSpaceForces
    % Class for running the getJointSpaceForces function and
    % storing/working with the resulting data. This includes analysing the
    % residual force to make sure it's low enough (this is not the same as
    % the residuals from RRA). 
    
    % For the moment COMPLETING THIS CLASS IS ON HOLD!
    % When you come back remember the necessary intricacies of subsampling
    % etc. Or potential use SMOOTHM matlab - google this. Try both.
    % Alternatively could try to access Simbody GCV Spline fitter. (Think
    % this has an OpenSim implementation but it seems to vary).
    
    properties (SetAccess = private)
        trial % OpenSimTrial with RRA calculated
        results % Results directory
        jsf = 'Not yet calculated.'
    end
    
    properties (GetAccess = private, SetAccess = private)
        idTrial % Trial using RRA as input to get ID.
    end
    
    methods
        
        % Construct JointSpaceForces from an OpenSimTrial and desired
        % results directory. 
        function obj = JointSpaceForces(OpenSimTrial, results_directory)
            if nargin > 0
                if strcmp(OpenSimTrial.rra, 'Not yet calculated.')
                    error(['OpenSimTrial must be evaluated up to and '...
                        'including RRA in order to calculate joint space '...
                        'forces.']);
                end
                obj.ost = OpenSimTrial;
                obj.results_directory = ...
                    createUniqueDirectory(results_directory);
            end
        end
        
        function obj = calcIDTrial(obj, directory)
            obj.idTrial = OpenSimTrial(obj.trial.model_path, ...
                                       obj.trial.rra.positions_path, ...
                                       obj.trial.grfs_path, ...
                                       [directory '/ID']);
            obj.idTrial.runID( ...
                'normal', obj.trial.rra.start, obj.trial.rra.final);
        end
        
        function obj = calcJointSpaceForces(obj, directory)
            % Calculates and stores the joint space forces for the object. 
            % Outputs JSF data to the provided directory.
            current_directory = pwd;
            cd([getenv('EXOPT_HOME') '/bin']);
            
            %%STOP%%
            % This has to be subsampled to the correct frequency 
            % before going in to getJointSpaceForces!
            [run_status, cmdout] = system(['getJointSpaceForce.exe' ...
                obj.model_path, obj.ext_path, obj.rra.states_path, ...
                obj.rra.accelerations_path, obj.id]);
            
        end
        
        function status = analyseResiduals(obj)
            % Want this function to analyse residuals and see if they're
            % good enough. 
        end
    
    end
end

