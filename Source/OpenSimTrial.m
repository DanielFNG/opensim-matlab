classdef OpenSimTrial < handle
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
        computed
    end
    
    properties (GetAccess = private, SetAccess = private)
        defaults
        marker_data 
        best_kinematics
    end
    
    methods
        % Construct OpenSimTrial.
        function obj = OpenSimTrial(model, ...
                                    input, ...
                                    results, ...
                                    grfs)
            if nargin > 0
                if nargin > 3
                    obj.grfs_path = rel2abs(grfs);
                end
                [obj.model_path, obj.input_coordinates, ...
                    obj.results_directory] = rel2abs(model, input, results);
                obj.best_kinematics = obj.input_coordinates;
                if ~exist(obj.results_directory, 'dir')
                    mkdir(obj.results_directory);
                end
                obj.analyseInputCoordinates();
                obj.loadDefaults();
            end
        end
        
        % Prints a message descriping the computation status of the OST.
        function status(obj)
            fprintf('\nModel adjustment %scompleted.\n', ...
                OpenSimTrial.statusMessage(obj.computed.model_adjustment));
            fprintf('\nIK %scomputed.\n', ...
                OpenSimTrial.statusMessage(obj.computed.IK));
            fprintf('RRA %scomputed.\n', ...
                OpenSimTrial.statusMessage(obj.computed.RRA));
            fprintf('BK %scomputed.\n', ...
                OpenSimTrial.statusMessage(obj.computed.BK));
            fprintf('ID %scomputed.\n', ...
                OpenSimTrial.statusMessage(obj.computed.ID));
            fprintf('CMC %scomputed.\n\n', ...
                OpenSimTrial.statusMessage(obj.computed.CMC));
        end
        
        function run(obj, method, varargin)
            
            obj.checkValidity(method);
            
            % Parse inputs.
            options = obj.parseAnalysisArguments(method, varargin{:});
            
            % Setup analysis.
            if strcmp(method, 'ID')
                [tool, file] = obj.setup(method, options);
            else
                tool = obj.setup(method, options);
            end
            
            % Run analysis.
            tool.run();
            obj.computed.(method) = true;
            
            if strcmp(method, 'IK')
                obj.best_kinematics = [options.results filesep 'ik.mot'];
            elseif strcmp(method, 'RRA')
                obj.best_kinematics = ...
                    [options.results filesep 'RRA_Kinematics_q.sto'];
            elseif strcmp(method, 'ID')
                delete(file);
            end
            
        end
        
        function fullRun(obj, varargin)
            
            for i = 1:length(obj.defaults.methods)
                obj.run(obj.defaults.methods{i}, varargin{:});
            end
            
        end   
            
        function performModelAdjustment(...
                obj, body, new_model, human_model, varargin)
            
            if ~obj.computed.IK || isempty(obj.grfs_path)
                error('Require IK and grfs to perform mass adjustment.');
            end
            
            options = obj.parseAnalysisArguments('RRA', varargin{:});
            
            % Setup adjustment RRA.
            rraTool = obj.setupAdjustmentRRA(body, new_model, ...
                options.timerange, options.results, options.load, ...
                options.settings);
            
            % Run RRA.
            rraTool.run();
            
            % Perform mass adjustments.
            obj.performMassAdjustment(...
                new_model, human_model, getenv('OPENSIM_MATLAB_OUT')); 
            
            obj.computed.model_adjustment = true;
        end
        
    end
    
    methods (Access = private)
        
        % Load the filenames for default RRA, ID settings etc. 
        function loadDefaults(obj)
            % Get access to the OPENSIM_MATLAB Defaults folder.
            default_folder = [getenv('OPENSIM_MATLAB_HOME') filesep 'Defaults'];
            
            % Allowable methods.
            obj.defaults.methods = {'IK', 'RRA', 'BK', 'ID', 'CMC'};
            
            % Assign default settings paths. 
            obj.defaults.settings.IK = ...
                [default_folder filesep 'IK' filesep 'ik.xml'];
            obj.defaults.settings.BK = ...
                [default_folder filesep 'BK' filesep 'bk.xml'];
            obj.defaults.settings.RRA = ...
                [default_folder filesep 'RRA' filesep 'settings.xml'];
            obj.defaults.settings.ID = ...
                [default_folder filesep 'ID' filesep 'id.xml'];
            obj.defaults.settings.CMC = ...
                [default_folder filesep 'CMC' filesep 'settings.xml'];
            obj.defaults.settings.loads = ...
                [default_folder filesep 'loads.xml'];
            
            % Assign default mass proportions. 
            obj.defaults.prop = [default_folder filesep 'mass_proportions.txt'];
            
            % Assign default results files/directories. 
            obj.defaults.results.IK = [obj.results_directory filesep 'IK'];
            obj.defaults.results.ID = [obj.results_directory filesep 'ID'];
            obj.defaults.results.RRA = [obj.results_directory filesep 'RRA'];
            obj.defaults.results.BK = [obj.results_directory filesep 'BK'];
            obj.defaults.results.CMC = [obj.results_directory filesep 'CMC'];
            
            % Set statuses to 0.
            obj.computed.IK = false;
            obj.computed.model_adjustment = false;
            obj.computed.RRA = false;
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
            if round(n_args/2) ~= n_args/2
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
                options.timerange = kinematics.getTimeRange();
            end
        end
        
        function checkValidity(obj, method)
            
            if ~any(strcmpi(obj.defaults.methods, method))
                error('Method not recognised.');
            elseif strcmpi(method, 'IK')
                if isempty(obj.marker_data)
                    error('Marker data not provided.');
                end
            else
                if isempty(obj.grfs_path)
                    error(['External forces required for analyses other' ...
                        ' than IK.']);
                elseif ~obj.computed.IK 
                    error('Require IK to compute subsequent analyses.');
                end
            end
            
        end
        
        function varargout = setup(obj, method, options)
            
            switch method
                case 'IK'
                    varargout{1} = obj.setupIK(...
                        options.timerange, options.results, options.settings);
                case 'BK'
                    varargout{1} = obj.setupBK(options.timerange, ...
                        options.results, options.settings);
                case 'ID'
                    [varargout{1}, varargout{2}] = obj.setupID(...
                        options.timerange, options.results, options.load, ...
                        options.settings);
                case 'RRA'
                    varargout{1} = obj.setupRRA(options.timerange, ...
                        options.results, options.load, options.settings);
                case 'CMC'
                    varargout{1} = obj.setupCMC(options.timerange, ...
                        options.results, options.load, options.settings);
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
            if ~exist(results, 'dir')
                mkdir(results);
            end
            ikTool.setResultsDir(results);
            ikTool.setOutputMotionFileName([results filesep 'ik.mot']);
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
            bkTool.setCoordinatesFileName(obj.best_kinematics);
            bkTool.setInitialTime(timerange(1));
            bkTool.setFinalTime(timerange(2));
            bkTool.setResultsDir(results);
        end
        
        function rraTool = setupRRA(obj, timerange, results, load, settings)
            % Temporarily copy RRA settings folder to new location.
            [folder, name, ext] = fileparts(settings);
            temp_settings = [results filesep 'temp'];
            copyfile(folder, temp_settings);
            settings = [temp_settings filesep name ext];
            
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
            while true
                if exist(temp, 'file')
                    delete(temp);
                    break;
                end
            end
            
            % Remove temporary settings folder. 
            rmdir(temp_settings, 's');
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
            rraTool.setOutputModelFileName(new_model);
        end
        
        % Performs the mass adjustments recommended by the RRA algorithm.
        function performMassAdjustment(obj, new_model, human_model, log)
            % Load the models. 
            import org.opensim.modeling.Model;
            overall_model = Model(obj.model_path);
            human_model = Model(human_model);
            
            % Get the bodies which should be adjusted, their names and masses.
            adjustable_bodies = human_model.getBodySet();
            names = {};
            masses = [];
            for i = 0:adjustable_bodies.getSize() - 1
                name = adjustable_bodies.get(i).getName();
                if ~strcmpi(name, 'ground')
                    names{end + 1} = name; %#ok<*AGROW>
                    masses(end + 1) = adjustable_bodies.get(i).getMass(); 
                end
            end
            
            % Calculate mass proportions using human model.
            total_mass = sum(masses);
            proportions = masses/total_mass;
            
            % Find the total mass to be changed in the overall model.
            mass_change = obj.getTotalMassChange(log);
            
            % Step through the bodies applying the correct mass changes.
            for i=1:length(names)
                current_mass = overall_model.getBodySet.get(names{i}).getMass();
                overall_model.getBodySet.get(names{i}).setMass(...
                    current_mass + ...
                    mass_change * proportions(i));
            end
            
            % Produce the adjusted model file.
            overall_model.print(new_model);
        end
        
        function [idTool, temp] = ...
                setupID(obj, timerange, results, load, settings)
            % Import OpenSim IDTool class.
            import org.opensim.modeling.InverseDynamicsTool;
            
            % Load IDTool.
            idTool = InverseDynamicsTool(settings);
            
            % Assign parameters. 
            idTool.setModelFileName(obj.model_path);
            if ~exist(results, 'dir')
                mkdir(results)
            end
            idTool.setResultsDir(results);
            idTool.setOutputGenForceFileName('id.sto');
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
            
            % Temporarily copy CMC settings folder to new location.
            [folder, name, ext] = fileparts(settings);
            temp_settings = [results filesep 'temp'];
            copyfile(folder, temp_settings);
            settings = [temp_settings filesep name ext];
            
            % Modify pelvis COM in actuators file.
            obj.modifyPelvisCOM(settings);
            
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
            cmcTool.createExternalLoads(temp, cmcTool.getModel());
            while true
                if exist(temp, 'file')
                    delete(temp);
                    break;
                end
            end
            
            % Remove temporary settings folder.
            rmdir(temp_settings, 's');
        end
    end
    
    methods(Static, Access = private)
        
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
                message = '';
            else
                message = 'not ';
            end
        end
        
    end   
end

