classdef OpenSimTrial2 < handle
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
        grfs_path % path to external forces data
        input_coordinates % path to kinematics
        results_directory % path to high level results directory
    end
    
    properties (GetAccess = private, SetAccess = private)
        defaults
        computed
        marker_data 
        best_kinematics
    end
    
    methods
        % Construct OpenSimTrial.
        function obj = OpenSimTrial2(model, ...
                                    input, ...
                                    grfs, ...
                                    results)
            if nargin > 0
                obj.model_path = model;
                obj.grfs_path = grfs;
                obj.input_coordinates = input;
                obj.best_kinematics = input;
                if ~exist(results, 'dir')
                    mkdir(results);
                end
                obj.results_directory = results;
                obj.analyseInputCoordinates;
                obj.loadDefaults();
            end
        end
        
        % Prints a message descriping the computation status of the OST.
        function status(obj)
            fprintf('\nIK %s.\n', ...
                OpenSimTrial2.statusMessage(obj.computed.ik));
            fprintf('AdjustmentRRA %s.\n', ...
                OpenSimTrial2.statusMessage(obj.computed.rra_adjusted));
            fprintf('RRA %s.\n', ...
                OpenSimTrial2.statusMessage(obj.computed.rra));
            fprintf('BK %s.\n', ...
                OpenSimTrial2.statusMessage(obj.computed.bk));
            fprintf('ID %s.\n', ...
                OpenSimTrial2.statusMessage(obj.computed.id));
            fprintf('CMC %s.\n\n', ...
                OpenSimTrial2.statusMessage(obj.computed.cmc));
        end     
        
        function runIK(obj, varargin)
            
            % Check compuation status.
            if isempty(obj.marker_data)
                error('Marker data not provided.');
            end
            
            % Parse inputs. 
            options = obj.parseAnalaysisArguments('IK', varargin{:});
                
            % Setup IK.
            ikTool = obj.setupIK(...
                options.timerange, options.results, options.settings);
            
            % Run IK.
            ikTool.run();
            obj.computed.IK = true;
            
            % Store the best current kinematics for this trial.
            obj.best_kinematics = results;
        end
        
        function runBK(obj, varargin)
            
            % Check computation status. 
            if ~obj.computed.IK
                error('Require IK to compute BK.');
            end
            
            options = obj.parseAnalysisArguments('BK', varargin{:});
            
            % Setup BK.
            bkTool = obj.setupBK(options.timerange, options.results, ...
                options.load, options.settings);
            
            % Run BK.
            bkTool.run();
            obj.computed.BK = true;
        end
        
        function runID(obj, varargin)
        
            if ~obj.computed.IK
                error('Require at least IK to compute ID.');
            end
            
            options = obj.parseAnalysisArguments('ID', varargin{:});
                
            % Setup ID.
            [idTool, temp] = obj.setupID(options.timerange, options.results, ...
                options.load, options.settings);
            
            % Run ID.
            idTool.run();
            obj.computed.ID = true;
            
            % Delete temp file.
            delete(temp);    
        end
        
        function runRRA(obj, varargin)
            
            if ~obj.computed.IK
                error('Require IK to compute RRA.');
            end
            
            options = obj.parseAnalysisArguments('RRA', varargin{:});
            
            % Setup RRA.
            rraTool = obj.setupRRA(options.timerange, options.results, ...
                options.load, options.settings);
            
            % Run RRA.
            rraTool.run()
            obj.computed.RRA = true;
            
            % Store the best current kinematics for this trial.
            obj.best_kinematics = [results filesep 'RRA_Kinematics_q.sto'];
        end
            
        function runAdjustmentRRA(obj, body, new_model, varargin)
            
            if obj.computed.RRA
                error('RRA already computed or provided.');
            elseif ~obj.computed.IK
                error('Require IK to compute RRA.');
            end
            
            options = obj.parseAnalysisArguments('RRA', varargin{:});
            
            % Setup adjustment RRA.
            rraTool = obj.setupAdjustmentRRA(body, new_model, ...
                options.timerange, options.results, options.load, ...
                options.settings);
            
            % Run RRA.
            rraTool.run();
            obj.computed.RRA_adjusted = true;
            
            % Perform mass adjustments.
            obj.performMassAdjustments(new_model, getenv('OPENSIM_MATLAB_OUT')); 
        end
        
        function runCMC(obj, varargin)
            if obj.computed.CMC
                error('CMC already computed or provided.');
            elseif ~obj.computed.IK
                error('Require at least IK to compute CMC.');
            end
            
            options = obj.parseAnalysisArguments('CMC', varargin{:});
            
            % Setup CMC.
            cmcTool = obj.setupCMC(options.timerange, options.results, ...
                options.load, options.settings);
            
            % Run CMC.
            cmcTool.run();
            obj.computed.CMC = true;
        end
    end
    
    methods (Access = private)
        
        % Load the filenames for default RRA, ID settings etc. 
        function loadDefaults(obj)
            % Get access to the OPENSIM_MATLAB Defaults folder.
            default_folder = [getenv('OPENSIM_MATLAB_HOME') filesep 'Defaults'];
            
            % Assign default settings paths. 
            obj.defaults.settings.IK = ...
                [default_folder filesep 'ik.xml'];
            obj.defaults.settings.BK = ...
                [default_folder filesep 'bk.xml'];
            obj.defaults.settings.RRA = ...
                [default_folder filesep 'RRA' filesep 'settings.xml'];
            obj.defaults.settings.ID = ...
                [default_folder filesep 'id.xml'];
            obj.defaults.settings.CMC = ...
                [default_folder filesep 'CMC' filesep 'settings.xml'];
            obj.defaults.settings.loads = ...
                [default_folder filesep 'loads.xml'];
            
            % Assign default mass proportions. 
            obj.defaults.prop = [default_folder filesep 'mass_proportions.txt'];
            
            % Assign default results files/directories. 
            obj.defaults.results.IK = [obj.results_directory filesep 'ik.mot'];
            obj.defaults.results.ID = 'id.sto';
            obj.defaults.results.RRA = [obj.results_directory filesep 'RRA'];
            obj.defaults.results.BK = [obj.results_directory filesep 'BK'];
            obj.defaults.results.CMC = [obj.results_directory filesep 'CMC'];
            
            % Set statuses to 0.
            obj.computed.IK = false;
            obj.computed.RRA = false;
            obj.computed.RRA_adjusted = false;
            obj.computed.BK = false;
            obj.computed.ID = false;
            obj.computed.CMC = false;
        end
        
        function analyseInputCoordinates(obj)
            [~, ~, ext] = fileparts(obj.input_coordinates);
            
            if strcmp(ext, '.mot')
                obj.computed.IK = true;
                obj.best_kinematics = obj.input_coordinates;
            elseif strcmp(ext, '.sto')
                obj.computed.IK = true;
                obj.computed.RRA = true;
                obj.best_kinematics = obj.input_coordinates;
            elseif ~strcmp(ext, '.trc')
                error('Wrong file format for input kinematic data.');
            else
                obj.marker_data = obj.input_coordinates;
            end
        end
        
        function options = parseAnalysisArguments(obj, func, varargin)
        
            % Set the default arguments, note timerange handled separately.
            options = struct('timerange', false, ...
                'results', obj.defaults.results.(func), ...
                'settings', obj.defaults.settings.(func), ...
                'load', obj.defaults.settings.loads);
            
            % Get possible option names.
            option_names = fieldnames(options);
            
            % Check name-value pairs have been provided.
            n_args = length(varargin);
            if round(n_args/2) ~= nArgs/2
                error('Please use name value pair arguments.');
            end
            
            % Replace default options if specified by user. 
            for pair = reshape(varargin, 2, [])
                input_arg = lower(pair{1});
                
                if any(strcmp(input_arg, option_names))
                    options.(input_arg) = pair{2};
                else
                    error('%s is not a valid argument name', input_arg)
                end
            end
            
            % Replace time with full range if not specified by user.
            if ~options.timerange
                if strcmp(func, 'IK')
                    kinematics = Data(obj.marker_data);
                else
                    kinematics = Data(obj.best_kinematics);
                end
                options.timerange = ...
                    [kinematics.Timesteps(1, 1), kinematics.Timesteps(end, 1)];
            end
        end 
        
        function ikTool = setupIK(obj, timerange, results, settings)
            % Import OpenSim IKTool class and Model class.
            import org.opensim.modeling.InverseKinematicsTool;
            import org.opensim.modeling.Model;
            
            % Load IKTool.
            ikTool = InverseKinematicsTool(settings);
            
            % Assign parameters.
            model = Model(obj.model_path);
            ikTool.setModel(model);
            ikTool.setStartTime(timerange(1));
            ikTool.setEndTime(timerange(2));
            ikTool.setMarkerDataFileName(obj.marker_data);
            ikTool.setOutputMotionFileName(results);
        end
        
        function bkTool = setupBK(obj, timerange, results, settings)
            % Import OpenSim AnalyzeTool class and Model class.
            import org.opensim.modeling.AnalyzeTool;
            import org.opensim.modeling.Model;
            
            % Load bkTool.
            bkTool = AnalyzeTool(settings);
            
            % Assign parameters.
            model = Model(obj.model_path);
            model.initSystem();
            bkTool.setModel(model);
            tool.setCoordinatesFileName(obj.best_kinematics);
            tool.setInitialTime(timerange(1));
            tool.setFinalTime(timerange(2));
            tool.setResultsDir(results);
        end
        
        function rraTool = setupRRA(obj, timerange, results, load, settings)
            % Modify pelvis COM in actuators file.
            obj.modifyPelvisCOM(settings);
            
            % Import OpenSim RRATool class.
            import org.opensim.modeling.RRATool;
            
            % Load RRATool.
            rraTool = RRATool(settings);
            
            % Assign parameters.
            rraTool.setModelFilename(obj.model_path);
            rraTool.loadModel(settings);
            rraTool.updateModelForces(rraTool.getModel(), settings);
            rraTool.setInitialTime(timerange(1));
            rraTool.setFinalTime(timerange(2));
            rraTool.setDesiredKinematicsFileName(obj.best_kinematics);
            rraTool.setResultsDir(results);
            
            % Set external loads.
            ext = xmlread(load);
            ext.getElementsByTagName('datafile').item(0).getFirstChild. ...
                setNodeValue(obj.grfs_path);
            temp = [results filesep 'temp.xml'];
            xmlwrite(temp, ext);
            rraTool.createExternalLoads(temp, rraTool.getModel());
            delete(temp);
        end
        
        % Modify the pelvis COM in the default RRA_actuators file in order
        % to match the pelvis COM of the input model. 
        function modifyPelvisCOM(obj, settings)
            % Import OpenSim libraries & get default actuators file path.
            import org.opensim.modeling.Vec3
            import org.opensim.modeling.Model
            
            [folder, ~, ~] = fileparts(settings);
            actuators_path = [folder filesep 'actuators.xml'];
            
            % Store the pelvis COM from the model file. 
            model = Model(obj.model_path);
            com = Vec3();
            model.getBodySet.get('pelvis').getMassCenter(com);
            
            % Convert the pelvis COM to a string. 
            com_string = sprintf('%s\t', num2str(com.get(0)), ...
                num2str(com.get(1)), num2str(com.get(2)));
            com_string = [' ', com_string];
            
            % Read in the default actuators xml and identify the body nodes. 
            actuators = xmlread(actuators_path);
            bodies = actuators.getElementsByTagName('body');
            
            % Change the CoM for each of FX/FY/FZ. We skip i=0 since this
            % occurs in the 'default' node. 
            for i=1:3
                bodies.item(i).getNextSibling().getNextSibling(). ...
                    setTextContent(com_string);
            end
            
            % Rewrite the actuators file with the changes. 
            xmlwrite(actuators_path, actuators);
        end
        
        function rraTool = setupAdjustmentRRA(...
                obj, body, new_model, timerange, results, load,  settings)
            % General RRA settings.
            rraTool = obj.setupRRA(timerange, results, load, settings);
            
            % Adjustment specific settings.
            rraTool.setAdjustCOMToReduceResiduals(true);
            rraTool.setAdjustedCOMBody(body);
            rraTool.setOutputModelFileName([results filesep new_model]);
        end
        
        % Performs the mass adjustments recommended by the RRA algorithm.
        function performMassAdjustments(obj, new_model, log)
            % Load the model. 
            import org.opensim.modeling.Model;
            osim = Model(obj.model_path);
            
            % Find the total mass change.
            mass = obj.getTotalMassChange(log);
            
            % Load the gait2392 mass proportion file. 
            proportions = Data(obj.defaults.prop);
            
            % Step through the bodies applying the correct mass changes.
            for i=1:size(proportions.Values,2)
                osim.getBodySet.get(proportions.Labels(1,i)).setMass(...
                    osim.getBodySet.get(proportions.Labels(1,i)).getMass() + ...
                    mass * proportions.Values(1,i));
            end
            
            osim.print(new_model);
        end
        
        function [idTool, temp] = ...
                setupID(obj, timerange, results, load, settings)
            % Import OpenSim IDTool class.
            import org.opensim.modeling.InverseDynamicsTool;
            
            % Load IDTool.
            idTool = InverseDynamicsTool(settings);
            
            % Assign parameters. 
            idTool.setModelFileName(obj.model_path);
            idTool.setResultsDir(obj.results_directory);
            idTool.setOutputGenForceFileName(results);
            idTool.setStartTime(timerange(1));
            idTool.setEndTime(timerange(2));
            idTool.setCoordinatesFileName(obj.best_kinematics);
            
            % Set external loads.
            ext = xmlread(load);
            ext.getElementsByTagName('datafile').item(0).getFirstChild. ...
                setNodeValue(obj.grfs_path);
            temp = [obj.results_directory filesep 'temp.xml'];
            xmlwrite(temp, ext);
            idTool.setExternalLoadsFileName(temp);
        end
        
        function cmcTool = setupCMC(obj, timerange, results, load, settings)
            % Import OpenSim CMCTool class.
            import org.opensim.modeling.CMCTool
            
            % Load default CMCTool.
            cmcTool = CMCTool(settings);
            
            % Assign parameters.
            cmcTool.setModelFilename(obj.model_path);
            cmcTool.loadModel(settings);
            cmcTool.addAnalysisSetToModel();
            cmcTool.updateModelForces(cmcTool.getModel(), settings);
            cmcTool.setResultsDir(results);
            cmcTool.setInitialTime(timerange(1));
            cmcTool.setFinalTime(timerange(2));
            cmcTool.setDesiredKinematicsFileName(obj.best_kinematics);
            
            % Setup external loads.
            external_loads = xmlread(load);
            external_loads.getElementsByTagName('datafile').item(0). ...
                getFirstChild.setNodeValue(obj.grfs_path);
            temp = [results filesep 'temp.xml'];
            xmlwrite(temp, external_loads);
            cmcTool.createExternalLoads(temp, Tool.getModel());
            delete('temp.xml');
        end
    end
    
    methods(Static)
        
        % Find the total mass change suggested by an RRA log file. 
        function mass = getTotalMassChange(log)
            % Read in log file. 
            text = fileread(log);
            
            % Find correct point in log file. 
            start_index = strfind(text,'Total mass change: ');
            % We take the final start_index found, corresponding to the
            % last matching entry for 'Total mass change: ' in the log file.
            % i.e. we assume duplicate entries means that a log file has
            % been appended to, so we choose the latest one. 
            
            % Isolate the mass change value as a string, then convert to
            % type double. 
            split = strsplit(text(start_index(end):end), '\n');
            mass_string = strsplit(split{1,1}, ' ');
            mass = str2double(mass_string(end));
        end
        
        function message = statusMessage(bool)
            if bool
                message = 'computed';
            else
                message = 'not computed';
            end
        end
        
    end   
end

