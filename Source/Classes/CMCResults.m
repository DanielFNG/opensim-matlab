classdef CMCResults
    % A class for holding the results of a CMC, and doing any calculations
    % based on these results. 
    
    properties (SetAccess = private)
        OpenSimTrial = 'N/A'
        start
        final
        metabolics
        MomentArms
    end
    
    methods
        
        % Construct CMCResults from directory files are located and the
        % OpenSimTrial.
        function obj = CMCResults(directory, OpenSimTrial)
            if nargin > 0
                if nargin == 2
                    obj.OpenSimTrial = OpenSimTrial;
                end
                directory = getFullPath(directory);
                obj.metabolics = Data([directory '_MetabolicsReporter_probes.sto']);
                obj.start = obj.metabolics.Timesteps(1);
                obj.final = obj.metabolics.Timesteps(end);
                obj = obj.getMomentArms(directory);
            end
        end
        
        function obj = getMomentArms(obj, directory)
            import org.opensim.modeling.Model
            gait2392 = Model([getenv('EXOPT_HOME') filesep 'Defaults' ...
                filesep 'Model' filesep 'gait2392.osim']);
            for i=1:gait2392.getNumCoordinates()
                joint = char(gait2392.getCoordinateSet().get(i-1));
                obj.MomentArms.(joint) = Data([directory ...
                    '_MuscleAnalysis_MomentArm_' joint '.sto']);
            end
        end
            
    end
end