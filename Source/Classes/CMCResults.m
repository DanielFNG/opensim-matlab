classdef CMCResults
    % A class for holding the results of a CMC, and doing any calculations
    % based on these results. 
    
    properties (SetAccess = private)
        OpenSimTrial = 'N/A'
        start
        final
        forces
        powers
        metabolics
        activations
        MomentArms
    end
    
    methods
        
        % Construct CMCResults from directory files are located and the
        % OpenSimTrial.
        function obj = CMCResults(directory, OpenSimTrial, ~)
            if nargin > 0
                
                directory = getFullPath(directory);
                obj.forces = Data([directory '_Actuation_force.sto']);
                obj.powers = Data([directory '_Actuation_power.sto']);
                obj.metabolics = ...
					Data([directory '_MetabolicsReporter_probes.sto']);
                obj.activations = Data([directory '_controls.sto']);
                obj.start = obj.metabolics.Timesteps(1);
                obj.final = obj.metabolics.Timesteps(end);
                if nargin == 3
                    obj.OpenSimTrial = OpenSimTrial;
                elseif nargin == 2
                    if ~isa(OpenSimTrial, 'float')
                        obj.OpenSimTrial = OpenSimTrial;
                        obj.getMomentArms(directory);
                    end
                elseif nargin == 1
                    obj = obj.getMomentArms(directory);
                else
                    error('weird input arguments');
                end
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