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
        
        % varargin format: start, final, results, settings
        function runIK(obj, varargin)
            
            % Check compuation status.
            if isempty(obj.marker_data)
                error('Marker data not provided.');
            end
            
            % Parse inputs. 
            [start, final, results, settings] = ...
                obj.parseKinematicArgs('IK', varargin{:});
                
            % Setup IK.
            ikTool = obj.setupIK(start, final, results, settings);
            
            % Run IK.
            ikTool.run();
            obj.computed.ik = true;
            
            % Store the best current kinematics for this trial.
            obj.best_kinematics = results;
        end
        
        % varargin format: start, final, results, load, settings
        function runID(obj, varargin)
        
            if ~obj.computed.ik
                error('Require at least IK to compute ID.');
            end
            
            [start, final, results, load, settings] = ...
                obj.parseDynamicArgs('ID', varargin{:});
                
            % Setup ID.
            [idTool, temp] = obj.setupID(start, final, results, load, settings);
            
            % Run ID.
            idTool.run();
            obj.computed.id = true;
            
            % Delete temp file.
            delete(temp);    
        end
        
        % varargin format: start, final, results, load, settings
        function runRRA(obj, varargin)
            
            if ~obj.computed.ik
                error('Require IK to compute RRA.');
            end
            
            [start, final, results, load, settings] = ...
                obj.parseDynamicArgs('RRA', varargin{:});
            
            % Setup RRA.
            rraTool = obj.setupRRA(start, final, results, load, settings);
            
            % Run RRA.
            rraTool.run()
            obj.computed.rra = true;
            
            % Store the best current kinematics for this trial.
            obj.best_kinematics = [results filesep 'RRA_Kinematics_q.sto'];
        end
            
        % varargin format: start, final, results, load, settings
        function runAdjustmentRRA(obj, body, new_model, varargin)
            
            if obj.computed.rra
                error('RRA already computed or provided.');
            elseif ~obj.computed.ik
                error('Require IK to compute RRA.');
            end
            
            [start, final, results, load, settings] = ...
                obj.parseDynamicArgs('RRA', varargin{:});
            
            % Setup adjustment RRA.
            rraTool = obj.setupAdjustmentRRA(...
                body, new_model, start, final, results, load, settings);
            
            % Run RRA.
            rraTool.run();
            obj.computed.rra_adjusted = true;
            
            % Perform mass adjustments.
            obj.performMassAdjustments(new_model, getenv('OPENSIM_MATLAB_OUT')); 
        end
        
        function runCMC(obj, varargin)
            if obj.computed.cmc
                error('CMC already computed or provided.');
            elseif ~obj.computed.ik
                error('Require at least IK to compute CMC.');
            end
            
            [start, final, results, load, settings] = ...
                obj.parseDynamicArgs('CMC', varargin{:});
            
            % Setup CMC.
            cmcTool = obj.setupCMC(start, final, results, load, settings);
            
            % Run CMC.
            cmcTool.run();
            obj.computed.cmc = true;
        end
    end
    
    methods (Access = private)
        
        % Load the filenames for default RRA, ID settings etc. 
        function loadDefaults(obj)
            % Get access to the OPENSIM_MATLAB Defaults folder.
            default_folder = [getenv('OPENSIM_MATLAB_HOME') filesep 'Defaults'];
            
            % Assign default settings paths. 
            obj.defaults.settings.ik = ...
                [default_folder filesep 'ik.xml'];
            obj.defaults.settings.bk = ...
                [default_folder filesep 'bk.xml'];
            obj.defaults.settings.rra = ...
                [default_folder filesep 'RRA' filesep 'settings.xml'];
            obj.defaults.settings.id = ...
                [default_folder filesep 'id.xml'];
            obj.defaults.settings.cmc = ...
                [default_folder filesep 'CMC' filesep 'settings.xml'];
            obj.defaults.settings.loads = ...
                [default_folder filesep 'loads.xml'];
            
            % Assign default mass proportions. 
            obj.defaults.prop = [default_folder filesep 'mass_proportions.txt'];
            
            % Assign default results files/directories. 
            obj.defaults.results.ik = [obj.results_directory filesep 'ik.mot'];
            obj.defaults.results.id = 'id.sto';
            obj.defaults.results.rra = [obj.results_directory filesep 'RRA'];
            obj.defaults.results.bk = [obj.results_directory filesep 'BK'];
            obj.defaults.results.cmc = [obj.results_directory filesep 'CMC'];
            
            % Set statuses to 0.
            obj.computed.ik = false;
            obj.computed.rra = false;
            obj.computed.rra_adjusted = false;
            obj.computed.bk = false;
            obj.computed.id = false;
            obj.computed.cmc = false;
        end
        
        function analyseInputCoordinates(obj)
            [~, ~, ext] = fileparts(obj.input_coordinates);
            
            if strcmp(ext, '.mot')
                obj.computed.ik = true;
                obj.best_kinematics = obj.input_coordinates;
            elseif strcmp(ext, '.sto')
                obj.computed.ik = true;
                obj.computed.rra = true;
                obj.best_kinematics = obj.input_coordinates;
            elseif ~strcmp(ext, '.trc')
                error('Wrong file format for input kinematic data.');
            else
                obj.marker_data = obj.input_coordinates;
            end
        end
        
        function [start, final, results, settings] = ...
            parseKinematicArgs(obj, func, start, final, results, settings)
            % Set the default results/settings based on function.
            if strcmp(func, 'IK') 
                default_settings = obj.defaults.settings.ik;
                default_results = obj.defaults.results.ik;
            elseif strcmp(func, 'BK')
                default_settings = obj.defaults.settings.bk;
                default_results = obj.defaults.results.bk;
            elseif strcmp(func, 'RRA')
                default_settings = obj.defaults.settings.rra; 
                default_results = obj.defaults.results.rra;
            elseif strcmp(func, 'ID')
                default_settings = obj.defaults.settings.id; 
                default_results = obj.defaults.results.id;
            elseif strcmp(func, 'CMC')
                default_settings = obj.defaults.settings.cmc; 
                default_results = obj.defaults.results.cmc;
            end
            
            if nargin < 2 || nargin == 3 || nargin > 6
                error('Incorrect number of arguments.');
            end 
            if nargin ~= 6 
                settings = default_settings;
            end
            if nargin ~= 5
                results = default_results;
            end
            if nargin ~= 4
                if strcmp(func, 'IK')
                    kinematics = Data(obj.marker_data);
                else
                    kinematics = Data(obj.best_kinematics);
                end
                start = kinematics.Timesteps(1, 1);
                final = kinematics.Timesteps(end, 1);
            end
        end
        
        function [start, final, results, load, settings] = ...
            parseDynamicArgs(obj, func, start, final, results, load, settings)
            
            if nargin < 2 || nargin == 3 || nargin > 7 
                error('Incorrect number of arguments.');
            end
            if nargin < 6
                load = obj.defaults.settings.loads;
            end
            if nargin == 7 
                [start, final, results, settings] = obj.parseKinematicArgs(...
                    func, start, final, results, settings);
            elseif nargin == 6 || nargin == 5
                [start, final, results, settings] = obj.parseKinematicArgs(...
                    func, start, final, results);
            elseif nargin == 4
                [start, final, results, settings] = obj.parseKinematicArgs(...
                    func, start, final);
            else 
                [start, final, results, settings] = obj.parseKinematicArgs(...
                    func);
            end
        end 
        
        function ikTool = setupIK(obj, start, final, results, settings)
            % Import OpenSim IKTool class and Model class.
            import org.opensim.modeling.InverseKinematicsTool;
            import org.opensim.modeling.Model;
            
            % Load IKTool.
            ikTool = InverseKinematicsTool(settings);
            
            % Assign parameters.
            model = Model(obj.model_path);
            ikTool.setModel(model);
            ikTool.setStartTime(start);
            ikTool.setEndTime(final);
            ikTool.setMarkerDataFileName(obj.marker_data);
            ikTool.setOutputMotionFileName(results);
        end
        
        function rraTool = setupRRA(obj, start, final, results, load, settings)
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
            rraTool.setInitialTime(start);
            rraTool.setFinalTime(final);
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
                obj, body, new_model, start, final, results, load,  settings)
            % General RRA settings.
            rraTool = obj.setupRRA(start, final, results, load, settings);
            
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
                setupID(obj, start, final, results, load, settings)
            % Import OpenSim IDTool class.
            import org.opensim.modeling.InverseDynamicsTool;
            
            % Load IDTool.
            idTool = InverseDynamicsTool(settings);
            
            % Assign parameters. 
            idTool.setModelFileName(obj.model_path);
            idTool.setResultsDir(obj.results_directory);
            idTool.setOutputGenForceFileName(results);
            idTool.setStartTime(start);
            idTool.setEndTime(final);
            idTool.setCoordinatesFileName(obj.best_kinematics);
            
            % Set external loads.
            ext = xmlread(load);
            ext.getElementsByTagName('datafile').item(0).getFirstChild. ...
                setNodeValue(obj.grfs_path);
            temp = [obj.results_directory filesep 'temp.xml'];
            xmlwrite(temp, ext);
            idTool.setExternalLoadsFileName(temp);
        end
        
        function cmcTool = setupCMC(obj, start, final, results, load, settings)
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
            cmcTool.setInitialTime(start);
            cmcTool.setFinalTime(final);
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

