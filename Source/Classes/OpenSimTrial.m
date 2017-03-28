classdef OpenSimTrial
    % Class for holding the data relating to a an experimental trial and 
    % performing various OpenSim operations. Results are printed to file
    % using the OpenSim tools and also stored as Data or RRAData objects in
    % Matlab variables. 
    %
    %   Basically, going to associate each OpenSim trial with a model
    %   (scaled, but in theory this could just be a default model and
    %   scaling could be part of this - but currently scaling is quite a
    %   manual process), an IK file (could be a marker file in future...)
    %   and a grf file. So basically I'll have functions for doing RRA and
    %   ID given these files, and could potentially add support for more
    %   OpenSim related stuff. 
    %
    %   The reason I'm doing this on top of what OpenSim already offers is
    %   that I want to hide a large portion of the functionality which we are
    %   unlikely to use, and simplify things by having default settings and
    %   settings files without having to actually supply loads files.
    
    properties (SetAccess = private)
        model_path % path to model
        grfs_path % path to grfs
        grfs % grfs data object
        kinematics_path % path to kinematics
        kinematics % kinematics data object 
        results_directory % path to high level results directory
        rra = 'Not yet calculated.'
        id = 'Not yet calculated.'
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
                                    grfs, ...
                                    results)
            % Path names must be given as full system paths, or they must be
            % relative paths and within the Matlab search path. Maybe need a
            % 'getFullPaths' function...
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
            end
        end
        
        % Setup RRA from the default settings file, with input initial and
        % final times, according to the OpenSimTrial properties. 
        function rraTool = setupRRA(obj, dir, loadType, initialTime, ... 
                                    finalTime, body, output)
            % Import OpenSim RRATool class. 
            import org.opensim.modeling.RRATool
            
            % Load default RRATool.
            rraTool = RRATool([obj.default_rra 'settings.xml']);

            obj.loadModelAndActuators(rraTool);
            obj.setInputsAndOutputs(rraTool, initialTime, finalTime, dir);
            obj.setupExternalLoads(rraTool, loadType);
            
            % Handle logic for whether or not the model should be adjusted.
            switch nargin 
                case 5
                    display('No model adjustment.');
                case 7
                    display('Adjusting COM according to specification.');
                    obj.makeAdjustmentsForRRA(rraTool, body, output); 
                otherwise
                    error('Incorrect number of arguments to setupRRA');
            end
        end
        
        % Set model, load it and apply the default gait2392_actuators file. 
        function loadModelAndActuators(obj, Tool)
            % Slightly different behaviour for RRA vs ID tools...
            if isa(Tool, 'org.opensim.modeling.RRATool')
                Tool.setModelFilename(obj.model_path);
                Tool.loadModel([obj.default_rra 'settings.xml']);
                Tool.updateModelForces(...
                    Tool.getModel(), [obj.default_rra 'settings.xml']);
            elseif isa(Tool, 'org.opensim.modeling.InverseDynamicsTool')
                %Tool.setModelFileName(obj.model_path);
                %import org.opensim.modeling.Model
                %Tool.setModel(Model(obj.model_path));
            else
                error('Unrecognized tool type.')
            end
        end
        
        % Set output directories, initial/final time and input files. 
        function setInputsAndOutputs(obj, Tool, initialTime, finalTime, dir)
            % Set results directory. 
            Tool.setResultsDir([obj.results_directory '/' dir]);
            
            % Settings different for RRA vs ID. 
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
        function makeAdjustmentsForRRA(obj, rraTool, body, output)
            rraTool.setAdjustCOMToReduceResiduals(true);
            rraTool.setAdjustedCOMBody(body);
            rraTool.setOutputModelFileName(...
                [obj.results_directory '/RRA/' output '.osim']);
        end
        
        % Setup external loads from type.
        function leftover = setupExternalLoads(obj, Tool, type)
            % Here, type defines what type of ExternalLoads case we have.
            % E.g. 2 forces for human walking, 4 for walking with APO.
            % There should be a unique xml file relating to any
            % ExternalLoads type located in Exopt/Defaults/ExternalLoads.    
            
            % Associate provided grfs with external loads.
            external_loads = xmlread([obj.default_ext type '.xml']);
            external_loads.getElementsByTagName('datafile').item(0). ...
                getFirstChild.setNodeValue(obj.grfs_path);
            xmlwrite('temp.xml', external_loads);
            
            % Different behaviours for RRA and ID tools. 
            if isa(Tool, 'org.opensim.modeling.RRATool')
                Tool.createExternalLoads('temp.xml', Tool.getModel());
                delete('temp.xml');
                leftover = 0;
            elseif isa(Tool, 'org.opensim.modeling.InverseDynamicsTool')
                % IDTool lacks a getModel method, so have to let the
                % temporary externalforce file live a bit longer and let
                % the runID function use & delete it. 
%                 leftover = getFullPath('temp.xml');
%                 Tool.setExternalLoadsFileName(leftover);
                %Tool.updExternalLoads();
                import org.opensim.modeling.Model
                model = Model(obj.model_path);
                Tool.setModel(model);
                Tool.createExternalLoads('temp.xml', Tool.model());
                leftover = 0;
            else
                error('Tool not recognized.');
            end
        end
        
        % Run the RRA algorithm.
        function obj = runRRA(...
                obj, loadType, initialTime, finalTime, body, output)
            % Setup RRATool.
            switch nargin
                case 4
                    rraTool = obj.setupRRA(...
                                'RRA', loadType, ...
                                    initialTime, finalTime);
                case 6
                    rraTool = obj.setupRRA(...
                                'RRA', loadType,...
                                    initialTime, finalTime, body, output);
                otherwise
                    error('Incorrect number of arguments to setupRRA');
            end
            
            % Run RRA.
            rraTool.run();
            
            % Process resulting RRA data. Default settings has name 'RRA'. 
            obj.rra = RRAResults('RRA', [obj.results_directory '/RRA']); 
        end
        
        % Function to do RRA from a user-provided file rather than based on
        % the default.  
        function obj = runRRAFromFile(obj, file)
            rraTool = RRATool(file);
            rraTool.run();
            obj.rra = RRAResults('RRA', [obj.results_directory '/RRA']);
        end
        
        % Setup ID from the default settings file, with input initial and
        % final times, according to the OpenSimTrial properties. 
        function [idTool, leftover] = setupID(...
                obj, dir, loadType, initialTime, finalTime)
            % Import OpenSim IDTool class.
            import org.opensim.modeling.InverseDynamicsTool
            
            % Load default InverseDynamicsTool.
            %idTool = InverseDynamicsTool([obj.default_id 'settings.xml']);
            idTool = InverseDynamicsTool();
            
            obj.loadModelAndActuators(idTool);
            obj.setInputsAndOutputs(idTool, initialTime, finalTime, dir);
            leftover = obj.setupExternalLoads(idTool, loadType);
        end
        
        % Run Inverse Dynamics. 
        function obj = runID(obj, loadType, initialTime, finalTime)
            % Setup InverseDynamicsTool.
            [idTool, leftover] = obj.setupID('ID', loadType, initialTime, finalTime);
            display(idTool.getModelFileName());
            display(idTool.getExternalLoads());
            display(idTool.getExternalLoadsFileName());
            idTool.setOutputGenForceFileName('id.sto');
            idTool.setLowpassCutoffFrequency(-1);
            idTool.run();
            %delete(leftover);
            obj.id = Data([obj.results_directory '/ID/id.sto']);
        end
        
        % Function to do ID from a user-provided file rather than based on
        % the default. 
        function obj = runIDFromFile(obj, file)
            idTool = InverseDynamicsTool(file);
            idTool.run();
            obj.id = Data([obj.results_directory '/ID/id.sto']);
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

