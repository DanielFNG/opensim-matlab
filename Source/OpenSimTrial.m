classdef OpenSimTrial < handle
% Class for running OpenSim analyses on input motion data.
%
% Provides simplified & programmatic access to OpenSim tools. Relies on default
% settings folder for setup, currently located in opensim-matlab/Defaults. 
% Currently only supports UoE-PelvisOrthosis setup but more will be added.  
    
    properties %(SetAccess = private)
        model_path  
        grfs_path  
        input_coordinates  
        results_paths
    end
    
    properties %(GetAccess = private, SetAccess = private)
        defaults
        marker_data 
        best_kinematics
        results_directory
    end
    
    properties (Access = {?SimData, ?DatasetElement})
       computed 
    end
    
    methods
    
        function obj = OpenSimTrial(model, input, results, grfs)
        % Construct OpenSimTrial.
        %   Input arguments:
        %       - model: path to model file
        %       - input: motion data, either markers or ik data
        %       - results: folder in which results are printed
        %       - grfs: motion data, external forces, required for some analyses
        %
            if nargin > 0
                
                % Get absolute paths.
                if nargin > 3
                    obj.grfs_path = rel2abs(grfs);
                end
                [obj.model_path, obj.results_directory] = ...
                    rel2abs(model, results);
                
                % Create results directory.
                if ~exist(obj.results_directory, 'dir')
                    mkdir(obj.results_directory);
                end
                
                % Load defaults. 
                obj.loadDefaults();
                
                if ~isempty(input)
                    obj.input_coordinates = rel2abs(input);
                    obj.analyseInputCoordinates();
                    obj.best_kinematics = obj.input_coordinates;
                end
                
            end
        end
        
        function computedStatus(obj)
        % Print a message describing the computation status of the OST.
        
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
            fprintf('SO %scomputed.\n', ...
                OpenSimTrial.statusMessage(obj.computed.SO));
            fprintf('CMC %scomputed.\n\n', ...
                OpenSimTrial.statusMessage(obj.computed.CMC));
        end
        
        function assertComputed(obj, analyses)
            % Assert that an analysis or set of analyses has been computed.
            
            if isa(analyses, 'char')
                analyses = {analyses};
            end
            
            for i=1:length(analyses)
                obj.computed.(analyses{i}) = true;
                obj.results_paths.(analyses{i}) = ...
                    obj.defaults.results.(analyses{i});
            end
        end
        
        function run(obj, analyses, varargin)
        % Run an analysis or set of analyses.
        % 
        % Input arguments:
        %   - analyses: a char or array of analyses to run e.g. {'IK', 'ID'}
        %   - varargin: name-value pair of arguments as follows
        %       - timerange: [start end] for trial
        %       - results: over-ride default save location
        %       - settings: over-ride default settings file
        %       - load: over-ride default load file
        
            % Compatability between running one or more analyses.
            if isa(analyses, 'char')
                analyses = {analyses};
            elseif any(strcmpi(varargin, 'settings'))
                error(['Optional ''settings'' argument not supported when ' ...
                    'running multiple analyses.']);
            end
            
            for i=1:length(analyses)
                
                method = analyses{i};
                
                % Check method is supported & correct data is available. 
                obj.checkValidity(method);
            
                % Parse inputs.
                options = obj.parseAnalysisArguments(method, varargin{:});
                
                % Run analysis.
                tic;
                success = obj.runTool(method, options);
                if ~success
                    t = toc;
                    fprintf(2, '%s\n', ['FAIL ' analyses{i} ' took ' ...
                        num2str(t) ' seconds - ' obj.input_coordinates]);
                end
                
                % Update computed status.
                obj.computed.(method) = true;
                
            end
            
        end
        
        function fullRun(obj, varargin)
        % Convenience method for running all supported OpenSim analyses.
        
            obj.run(obj.defaults.methods, varargin{:});
        end
            
        function performModelAdjustment(...
                obj, body, new_model, human_model, varargin)
        % Create a dynamically consistent model file using RRA. 
            
            if ~obj.computed.IK || isempty(obj.grfs_path)
                error('Require IK and grfs to perform mass adjustment.');
            end
            
            options = obj.parseAnalysisArguments('RRA', varargin{:});
            
            % Setup adjustment RRA.
            obj.runAdjustmentRRA(body, new_model, ...
                options.timerange, options.results, options.load, ...
                options.settings);
            
            % Perform mass adjustments.
            obj.performMassAdjustment(...
                new_model, human_model, getenv('OPENSIM_MATLAB_OUT')); 
            
            % Update computed status.
            obj.computed.model_adjustment = true;
        end
        
        function mass = getInputModelMass(obj)
            
            [mass, ~, ~] = obj.getModelMass(obj.model_path);
            
        end
        
    end
    
    methods (Access = private)
        
        function loadDefaults(obj)
        % Load default settings file paths, assign default directories & status.
        
            % Get access to the OPENSIM_MATLAB Defaults folder.
            default_folder = [getenv('OPENSIM_MATLAB_HOME') filesep 'Defaults'];
            
            % Allowable methods.
            obj.defaults.methods = {'IK', 'RRA', 'BK', 'ID', 'SO', 'CMC'};
            
            % Assign default settings paths. 
            obj.defaults.settings.IK = ...
                [default_folder filesep 'IK' filesep 'ik.xml'];
            obj.defaults.settings.BK = ...
                [default_folder filesep 'BK' filesep 'bk.xml'];
            obj.defaults.settings.RRA = ...
                [default_folder filesep 'RRA' filesep 'settings.xml'];
            obj.defaults.settings.ID = ...
                [default_folder filesep 'ID' filesep 'id.xml'];
            obj.defaults.settings.SO = ...
                [default_folder filesep 'SO' filesep 'settings.xml'];
            obj.defaults.settings.CMC = ...
                [default_folder filesep 'CMC' filesep 'settings.xml'];
            obj.defaults.settings.Analyse = ...
                [default_folder filesep 'Analyse' filesep 'settings.xml'];
            obj.defaults.settings.loads = ...
                [default_folder filesep 'loads.xml'];
            
            % Assign default results files/directories. 
            obj.defaults.results.IK = [obj.results_directory filesep 'IK'];
            obj.defaults.results.ID = [obj.results_directory filesep 'ID'];
            obj.defaults.results.RRA = [obj.results_directory filesep 'RRA'];
            obj.defaults.results.BK = [obj.results_directory filesep 'BK'];
            obj.defaults.results.SO = [obj.results_directory filesep 'SO'];
            obj.defaults.results.CMC = [obj.results_directory filesep 'CMC'];
            
            % Set statuses to 0.
            obj.computed.IK = false;
            obj.computed.model_adjustment = false;
            obj.computed.RRA = false;
            obj.computed.BK = false;
            obj.computed.ID = false;
            obj.computed.SO = false;
            obj.computed.CMC = false;
        end
        
        function analyseInputCoordinates(obj)
        % Set up different treatment of input motion data (markers/IK/RRA).
        
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
        % Allow user override of default settings parameters.
        
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
            
            % Set specific results directories.
            obj.results_paths.(func) = options.results;
        end
        
        function checkValidity(obj, method)
        % Check that an analysis can be run with the current data available. 
            
            if ~any(strcmpi(obj.defaults.methods, method))
                error('Method not recognised.');
            elseif strcmpi(method, 'IK')
                if isempty(obj.marker_data)
                    error('Marker data not provided.');
                end
            else
                if ~obj.computed.IK
                    error('Require IK to compute subsequent analyses.');
                elseif isempty(obj.grfs_path) && ~strcmp(method, 'BK')
                    error(['External forces required for analyses other' ...
                        ' than IK and BK.']);
                end
            end
            
        end
        
        function success = runTool(obj, method, options)
            
            switch method
                
                case 'IK'
                    
                    success = obj.runIK(options.timerange, options.results, ...
                        options.settings);
                    
                    % Filter IK data.
                    obj.filterIK();
                    
                    % Update best kinematics - unless RRA available. 
                    if ~obj.computed.RRA
                        obj.best_kinematics = ...
                            [options.results filesep 'ik.mot'];
                    end
                    
                case 'BK'
                    
                    success = obj.runBK(options.timerange, options.results, ...
                        options.settings);
                    
                case 'ID'
                    
                    success = obj.runID(options.timerange, options.results, ...
                        options.load, options.settings);
                    
                    % Filter ID data.
                    obj.filterID();
                    
                case 'RRA'
                    
                    success = obj.runRRA(options.timerange, options.results, ...
                        options.load, options.settings);
                    
                    % Update best kinematics.
                    obj.best_kinematics = ...
                        [options.results filesep 'RRA_Kinematics_q.sto'];
                    
                case 'SO'
                    success = obj.runSO(options.timerange, options.results, ...
                        options.load, options.settings);
                    
                case 'CMC'
                    
                    success = obj.runCMC(options.timerange, options.results, ...
                        options.load, options.settings);
            end
            
        end
        
        function success = runIK(obj, timerange, results, settings)
        % Sets up the IK Tool.
        
            % Import OpenSim IKTool class and Model class.
            import org.opensim.modeling.InverseKinematicsTool;
            import org.opensim.modeling.Model;
            
            % Load IKTool.
            ikTool = InverseKinematicsTool(settings);
            
            % Load & assign model.
            model = Model(obj.model_path);
            model.initSystem();
            ikTool.setModel(model);
            
            % Assign parameters.
            ikTool.setStartTime(timerange(1));
            ikTool.setEndTime(timerange(2));
            ikTool.setMarkerDataFileName(obj.marker_data);
            if ~exist(results, 'dir')
                mkdir(results);
            end
            ikTool.setResultsDir(results);
            ikTool.setOutputMotionFileName([results filesep 'ik.mot']);
            
            % Run tool.
            success = ikTool.run();
        end
        
        function success = runBK(obj, timerange, results, settings)
        % Sets up the BodyKinematics tool.
        
            % Import OpenSim AnalyzeTool class and Model class.
            import org.opensim.modeling.AnalyzeTool;
            import org.opensim.modeling.Model;
            
            % Load bkTool.
            bkTool = AnalyzeTool(settings, false);
            
            % Load & assign model.
            model = Model(obj.model_path);
            model.initSystem();
            bkTool.setModel(model);
            
            % Assign parameters. 
            bkTool.setCoordinatesFileName(obj.best_kinematics);
            bkTool.setInitialTime(timerange(1));
            bkTool.setFinalTime(timerange(2));
            bkTool.setResultsDir(results);
            bkTool.setLoadModelAndInput(true);
            
            % Run tool.
            success = bkTool.run();
        end
        
        function success = runRRA(obj, timerange, results, load, settings)
        % Sets up the RRA tool. 
        
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
            
            % Run tool.
            success = rraTool.run();
            
            % File cleanup.
            OpenSimTrial.attemptDelete(temp);
            OpenSimTrial.attemptDelete(temp_settings);
            
        end
        
        function success = runAdjustmentRRA(...
                obj, body, new_model, timerange, results, load,  settings)
        % Setup RRA - with additional settings for mass adjustment.
        
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
            
            % Adjustment specific settings.
            rraTool.setAdjustCOMToReduceResiduals(true);
            rraTool.setAdjustedCOMBody(body);
            rraTool.setOutputModelFileName(new_model);
            
            % Run tool.
            success = rraTool.run();
            
            % File cleanup.
            OpenSimTrial.attemptDelete(temp);
            OpenSimTrial.attemptDelete(temp_settings);
            
        end
        
        function success = runID(obj, timerange, results, load, settings)
        % Sets up the Inverse Dynamics tool.
        
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
            
            % Run tool.
            success = idTool.run();
            
            % File cleanup.
            OpenSimTrial.attemptDelete(temp);
        end
        
        function success = runSO(obj, timerange, results, load, settings)
        % Sets up the SO Tool.
        
            % Import OpenSim Analyze Tool.
            import org.opensim.modeling.AnalyzeTool;
            import org.opensim.modeling.Model;
            
            % Temporarily copy SO settings folder to new location.
            [folder, name, ext] = fileparts(settings);
            temp_settings = [results filesep 'temp'];
            copyfile(folder, temp_settings);
            settings = [temp_settings filesep name ext];
            
            % Modify pelvis COM in actuators file.
            obj.modifyPelvisCOM(settings);
            
            % Load tool.
            soTool = AnalyzeTool(settings);
            
            % Setup external loads.
            external_loads = xmlread(load);
            external_loads.getElementsByTagName('datafile').item(0). ...
                getFirstChild.setNodeValue(obj.grfs_path);
            temp = [results filesep 'temp.xml'];
            xmlwrite(temp, external_loads);
            soTool.setExternalLoadsFileName(temp);
            
            % Load and assign model.
            soTool.setModelFilename(obj.model_path);
            
            % Assign parameters.
            soTool.setCoordinatesFileName(obj.best_kinematics);
            soTool.setInitialTime(timerange(1));
            soTool.setFinalTime(timerange(2));
            soTool.setResultsDir(results);
            
            % Print new temp settings file.
            try
                soTool.print(settings);
            catch 
                pause(1.0);
                soTool.print(settings);
            end
            
            % Reload tool from these settings.
            soTool = AnalyzeTool(settings);
            
            % Run tool.
            success1 = soTool.run();

            % Separately do metabolic analyses - quite hardcoded for now. 
            metabolics_settings = obj.defaults.settings.Analyse;
            
            % Temporarily copy Analyse settings folder to new location.
            [folder, name, ext] = fileparts(metabolics_settings);
            temp_metabolics_settings = [results filesep 'temp2'];
            copyfile(folder, temp_metabolics_settings);
            metabolics_settings = [temp_metabolics_settings filesep name ext];
            
            % Modify pelvis COM in actuators file.
            obj.modifyPelvisCOM(metabolics_settings);
            
            % Load tool.
            soTool = AnalyzeTool(metabolics_settings);
            
            % Setup external loads.
            soTool.setExternalLoadsFileName(temp);
            
            % Load and assign model.
            soTool.setModelFilename(obj.model_path);
            
            % Assign parameters.
            soTool.setCoordinatesFileName(obj.best_kinematics);
            soTool.setInitialTime(timerange(1));
            soTool.setFinalTime(timerange(2));
            soTool.setResultsDir(results);
            soTool.setControlsFileName([results filesep ...
                'SO_StaticOptimization_controls.xml']);
            
            % Print new temp settings file.
            try
                soTool.print(metabolics_settings);
            catch 
                pause(1.0);
                soTool.print(metabolics_settings);
            end
            
            % Reload tool from these settings.
            soTool = AnalyzeTool(metabolics_settings);
            
            % Run tool.
            success2 = soTool.run();
            
            success = success1 && success2;
            
            % File cleanup.
            OpenSimTrial.attemptDelete(temp);
            OpenSimTrial.attemptDelete(temp_settings);
            OpenSimTrial.attemptDelete(temp_metabolics_settings);
            
        end
        
        function success = runCMC(obj, timerange, results, load, settings)
        % Sets up the CMC Tool.
        
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
            
            % Run tool.
            success = cmcTool.run();
            
            % File cleanup.
            OpenSimTrial.attemptDelete(temp);
            OpenSimTrial.attemptDelete(temp_settings);
        end
        
        function modifyPelvisCOM(obj, settings)
        % Modify pelvis COM in the copied actuators file to match input model.
        
            % Import OpenSim libraries & get default actuators file path.
            import org.opensim.modeling.Vec3
            import org.opensim.modeling.Model
            
            [folder, ~, ~] = fileparts(settings);
            actuators_path = [folder filesep 'actuators.xml'];
            
            % Store the pelvis COM from the model file. 
            model = Model(obj.model_path);
            com = model.getBodySet.get('pelvis').getMassCenter();
            
            % Convert the pelvis COM to a string. 
            com_string = sprintf('%s\t', num2str(com.get(0)), ...
                num2str(com.get(1)), num2str(com.get(2)));
            com_string = [' ', com_string];
            
            % Read in the default actuators xml and identify the body nodes. 
            actuators = xmlread(actuators_path);
            bodies = actuators.getElementsByTagName('body');
            
            % Change the CoM for each of FX/FY/FZ. We skip i=0 since this
            % occurs in the 'default' node. 
            for i=0:2
                bodies.item(i).getNextSibling().getNextSibling(). ...
                    setTextContent(com_string);
            end
            
            % Rewrite the actuators file with the changes. 
            try
                xmlwrite(actuators_path, actuators);
            catch
                pause(0.5);  % Sometimes we need to wait a bit... 
                xmlwrite(actuators_path, actuators); 
            end
                
        end
        
        function performMassAdjustment(obj, new_model, human_model, log)
        % Performs the mass adjustments recommended by the RRA algorithm.
            
            % Use human model to get the mass proportions for each body.
            [mass, names, masses] = obj.getModelMass(human_model);
            proportions = masses/mass;
            
            % Find the total mass to be changed in the overall model.
            mass_change = obj.getTotalMassChange(log);
            
            % Load the overall model. 
            import org.opensim.modeling.Model;
            overall_model = Model(obj.model_path);
            
            % Step through the bodies applying the correct mass changes.
            for i=1:length(names)
                current_mass = overall_model.getBodySet.get(names{i}).getMass();
                overall_model.getBodySet.get(names{i}).setMass(...
                    current_mass + mass_change * proportions(i));
            end
            
            % Produce the adjusted model file.
            overall_model.print(new_model);
        end
        
        function filterIK(obj)
           
            % Get IK filename
            file = [obj.results_paths.IK filesep 'ik.mot'];
            
            % Load, filter & reprint.
            data_object = Data(file);
            data_object.filter4LP(6);
            try
                data_object.writeToFile(file);
            catch
                pause(5);
                data_object.writeToFile(file);
            end
            delete(data_object);
            
        end
        
        function filterID(obj)
            
            % Get ID filename.
            file = [obj.results_paths.ID filesep 'id.sto'];
            
            % Load, filter & reprint.
            data_object = Data(file);
            data_object.filter4LP(4);
            try
                data_object.writeToFile(file);
            catch
                pause(5);
                data_object.writeToFile(file);
            end
            delete(data_object);
            
        end

    end
    
    methods (Static)
        
        function [mass, body_names, body_masses] = getModelMass(model_path)
        % Calculate mass of an OpenSim model.
        
            import org.opensim.modeling.Model;
            osim = Model(model_path);
            bodies = osim.getBodySet();
            n_bodies = bodies.getSize() - 1;
            body_names = cell(1, n_bodies);
            body_masses = zeros(1, n_bodies);
            
            % Sum the mass of every body in the model apart from ground.
            for i=0:n_bodies
                body_names{i + 1} = bodies.get(i).getName();
                body_masses(i + 1) = bodies.get(i).getMass();
            end
            mass = sum(body_masses);
        end
        
    end
    
    methods(Static, Access = private)
        
        function mass = getTotalMassChange(log)
        % Find the total mass change suggested by an RRA log file.
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
        % Small convenience method for printing OpenSimTrial completion status.
            if bool
                message = '';
            else
                message = 'not ';
            end
        end
        
        function attemptDelete(path)
        % Attempt to delete the directory or file at a given path.
        %
        % If unsuccessful, inform the user that manual deletion is required.
        
            if ~exist(path, 'dir')
                lastwarn('');
                delete(path);
                if strcmp(lastwarn, 'File not found or permission denied')
                    w = warning('query','last');
                    w.identifier
                    pause(0.5);
                    lastwarn('');
                    delete(path);
                    if strcmp(lastwarn, 'File not found or permission denied')
                        fprintf('%s requires manual deletion.\n', path);
                    end
                end
            else
                lastwarn('');
                try
                    rmdir(path, 's');
                catch
                    try
                        pause(0.5);
                        rmdir(path, 's');
                    catch
                        fprintf('%s requires manual deletion.\n', path);
                    end
                end
            end
        end
        
    end   
end

