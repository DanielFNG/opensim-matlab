classdef OpenSimTrial
    % Class for holding the data relating to a an experimental trial and 
    % performing various OpenSim operations. Results are printed to file
    % using the OpenSim tools and also stored as Data or RRAData objects in
    % Matlab variables. 
    %
    % Input files are the model file, kinematics and external force data,
    % and a desired results directory. 
    %   
    % The reason I'm doing this on top of what OpenSim already offers is
    % that I want to hide a large portion of the functionality which we are
    % unlikely to use, and more importantly allow simplified access to the 
    % RRA/ID tools that doesn't involve manually setting input/output files, 
    % timescales etc.
    %
    % This class relies on some default settings files e.g. the
    % gait2392_actuators file, & default settings files for ID/RRA. These 
    % are located in the Exopt/Defaults folder.
    
    properties (SetAccess = private)
        model_path % path to model
        human_dofs % degrees of freedom of model 
        grfs_path % path to external forces data 
        grfs % external forces data object
        load % A description of the external forces being applied
        load_path % Path to the load type file. 
        kinematics_path % path to kinematics
        kinematics % kinematics data object 
        results_directory % path to high level results directory
    end
    
    properties (GetAccess = private, SetAccess = private)
        default_rra 
        default_id
        default_ext
    end
    
    methods
        % Construct OpenSimTrial.
        function obj = OpenSimTrial(model, ...
                                    kinematics, ...
                                    load, ...
                                    grfs, ...
                                    results)
            if nargin > 0
                obj.model_path = getFullPath(model);
                obj.grfs_path = getFullPath(grfs);
                obj.grfs = Data(obj.grfs_path);
                obj.kinematics_path = getFullPath(kinematics);
                obj.kinematics = Data(obj.kinematics_path);
                new_results = createUniqueDirectory(results);
                obj.results_directory = getFullPath(new_results);
                [obj.default_rra, obj.default_id, obj.default_ext] = ...
                        obj.loadDefaults();
                obj.load = load; 
                obj.load_path = [obj.default_ext load '.xml'];
                % Import OpenSim Model class to calculate model dofs.  
                import org.opensim.modeling.Model;
                obj.human_dofs = Model(obj.model_path).getNumCoordinates();
            end
        end
        
        % Setup RRA from the default settings file, with input initial and
        % final times, according to the OpenSimTrial properties. 
        function rraTool = setupRRA(obj, dir, initialTime, ... 
                                    finalTime, body, output)
            % Import OpenSim RRATool class. 
            import org.opensim.modeling.RRATool
            
            % Load default RRATool.
            rraTool = RRATool([obj.default_rra 'settings.xml']);

            obj.loadModelAndActuators(rraTool);
            obj.setInputsAndOutputs(rraTool, initialTime, finalTime, dir);
            obj.setupExternalLoads(rraTool);
            
            % Handle logic for whether or not the model should be adjusted.
            switch nargin 
                case 4
                    display('No model adjustment.');
                case 6
                    display('Adjusting COM according to specification.');
                    obj.makeAdjustmentsForRRA(rraTool, body, output, dir); 
                otherwise
                    error('Incorrect number of arguments to setupRRA');
            end
        end
        
        % Set model, load it and apply the default gait2392_actuators file. 
        function loadModelAndActuators(obj, Tool)
            % RRA Tool requires specific behaviour. 
            if isa(Tool, 'org.opensim.modeling.RRATool')
                Tool.setModelFilename(obj.model_path);
                Tool.loadModel([obj.default_rra 'settings.xml']);
                Tool.updateModelForces(...
                    Tool.getModel(), [obj.default_rra 'settings.xml']);
            elseif isa(Tool, 'org.opensim.modeling.InverseDynamicsTool')
                Tool.setModelFileName(obj.model_path);
            else
                error('Unrecognized tool type.')
            end
        end
        
        % Set output directories, initial/final time and input files. 
        function setInputsAndOutputs(obj, Tool, initialTime, finalTime, dir)
            % Set results directory. 
            Tool.setResultsDir([obj.results_directory '/' dir]);
            
            % Slightly different behaviour for RRA vs ID. 
            if isa(Tool, 'org.opensim.modeling.RRATool')
                Tool.setInitialTime(initialTime);
                Tool.setFinalTime(finalTime);
                Tool.setDesiredKinematicsFileName(obj.kinematics_path);
            elseif isa(Tool, 'org.opensim.modeling.InverseDynamicsTool')
                Tool.setStartTime(initialTime);
                Tool.setEndTime(finalTime);
                Tool.setCoordinatesFileName(obj.kinematics_path);
            else
                error('Tool type not recognized.')
            end
        end
        
        % Settings for adjusting COM to reduce residuals. 
        function makeAdjustmentsForRRA(obj, rraTool, body, output, dir)
            rraTool.setAdjustCOMToReduceResiduals(true);
            rraTool.setAdjustedCOMBody(body);
            rraTool.setOutputModelFileName(...
                [obj.results_directory '/' dir '/' output '.osim']);
        end
        
        % Setup external loads from type.
        function setupExternalLoads(obj, Tool)
            % Here, type defines what type of ExternalLoads case we have.
            % E.g. 2 forces for human walking, 4 for walking with APO.
            % There should be a unique xml file relating to any
            % ExternalLoads type located in Exopt/Defaults/ExternalLoads.
            
            % Associate provided grfs with external loads in temporary settings
            % file. This file is later deleted in this script (for RRA) or
            % later (for ID) - read runID to see why we can't delete this
            % file here for ID. 
            external_loads = xmlread(obj.load_path);
            external_loads.getElementsByTagName('datafile').item(0). ...
                getFirstChild.setNodeValue(obj.grfs_path);
            xmlwrite('temp.xml', external_loads);
            
            if isa(Tool, 'org.opensim.modeling.InverseDynamicsTool')
                % Import Model class since InverseDynamicsTool doesn't have
                % a getModel method.
                import org.opensim.modeling.Model
                Tool.setExternalLoadsFileName(getFullPath('temp.xml'));
            elseif isa(Tool, 'org.opensim.modeling.RRATool')
                Tool.createExternalLoads('temp.xml', Tool.getModel());
                delete('temp.xml');
            else
                error('Incorrect number of arguments to setupExternalLoads.');
            end
        end
        
        % Run the RRA algorithm.
        function RRA = runRRA(...
                obj, initialTime, finalTime, body, output)
            % Setup RRATool.
            switch nargin
                case 3
                    dir = ['RRA_' 'load=' obj.load ...
                        '_time=' num2str(initialTime) '-' num2str(finalTime)];
                    rraTool = obj.setupRRA(...
                                dir, initialTime, finalTime);
                case 5
                    dir = ['RRA_' obj.load ...
                        '_time=' num2str(initialTime) '-' num2str(finalTime)...
                        '_withAdjustment'];
                    rraTool = obj.setupRRA(...
                                dir, initialTime, finalTime, body, output);
                otherwise
                    error('Incorrect number of arguments to setupRRA');
            end
            
            % Run RRA.
            rraTool.run();
            
            % Process resulting RRA data. Default settings has name 'RRA'. 
            RRA = RRAResults(obj, [obj.results_directory '/' dir '/RRA']); 
        end
        
        % Setup ID from the default settings file, with input initial and
        % final times, according to the OpenSimTrial properties. 
        function idTool = setupID(obj, dir, startTime, endTime)
            % Import OpenSim InverseDynamicsTool class.
            import org.opensim.modeling.InverseDynamicsTool
            
            % Load default InverseDynamicsTool.
            idTool = InverseDynamicsTool([obj.default_id 'settings.xml']);
            
            obj.loadModelAndActuators(idTool);
            obj.setInputsAndOutputs(idTool, startTime, endTime, dir);
            obj.setupExternalLoads(idTool);
        end
        
        % Run the ID algorithm. 
        function ID = runID(obj, startTime, endTime)
            
            dir = ['ID_' 'load=' obj.load ...
                '_time=' num2str(startTime) '-' num2str(endTime)];
            
            idTool = obj.setupID(dir,startTime,endTime);
            
            idTool.run();
            
            % Having to delete this file here is a byproduct of the OpenSim
            % InverseDynamicsTool class not having a getModel method. It's
            % not possible to associate external forces with an IDTool without
            % reading from a settings file. So, we have to let the external 
            % forces setup file survive until we run the tool and then delete 
            % it afterwards. 
            delete('temp.xml');
            
            % Create an IDResult object to store ID result. 
            ID = IDResult(obj, [obj.results_directory '/' dir '/']);
        end
    end
    
    methods(Static)
        
        % Load the filenames for default RRA, ID settings etc. 
        function [rra, id, ext] = loadDefaults()
            rra = [getenv('EXOPT_HOME') '/Defaults/RRA/'];
            id = [getenv('EXOPT_HOME') '/Defaults/ID/'];
            ext = [getenv('EXOPT_HOME') '/Defaults/ExternalLoads/'];
        end 
    end   
end

