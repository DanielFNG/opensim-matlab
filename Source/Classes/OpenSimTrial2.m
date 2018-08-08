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
        kinematics_path % path to kinematics
        results_directory % path to high level results directory
    end
    
    properties (GetAccess = private, SetAccess = private)
        defaults
        computed
        best_kinematics
    end
    
    methods
        % Construct OpenSimTrial.
        function obj = OpenSimTrial(model, ...
                                    kinematics, ...
                                    grfs, ...
                                    results)
            if nargin > 0
                obj.model_path = model;
                obj.grfs_path = grfs;
                obj.input_kinematics = kinematics;
                obj.best_kinematics = kinematics;
                if ~exist(results, 'dir')
                    mkdir(results);
                end
                obj.results_directory = results;
                obj.loadDefaults();
                
                % Import OpenSim model class.
                import org.opensim.modeling.Model;
            end
        end
        
        % Prints a message descriping the computation status of the OST.
        function status(obj)
            fprintf('\nIK %s.\n', ...
                OpenSimTrial.statusMessage(obj.computed.ik));
            fprintf('\nRRA %s.\n', ...
                OpenSimTrial.statusMessage(obj.computed.rra));
            fprintf('\nBK %s.\n', ...
                OpenSimTrial.statusMessage(obj.computed.bk));
            fprintf('\nID %s.\n', ...
                OpenSimTrial.statusMessage(obj.computed.id));
            fprintf('\nCMC %s.\n', ...
                OpenSimTrial.statusMessage(obj.computed.cmc));
        end     
        
        % varargin format: start, final, results, settings
        function runIK(obj, varargin)
            
            % Check compuation status.
            if obj.computed.ik
                error('IK already computed or provided.');
            end
            
            % Parse inputs. 
            [start, final, results, settings] = ...
                obj.parseKinematicArgs('IK', varargin);
                
            % Setup IK.
            ikTool = obj.setupIK(start, final, results, settings);
            
            % Run IK.
            ikTool.run();
            
            % Store the best current kinematics for this trial.
            obj.best_kinematics = results;
                
        end
        
        % varargin format: start, final, results, load, settings
        function runID(obj, varargin)
        
            if obj.computed.id
                error('ID already computed or provided.');
            elseif ~obj.computed.ik
                error('Require at least IK to compute ID.');
            end
            
            [start, final, results, load, settings] = ...
                obj.parseDynamicArgs('ID', varargin);
                
            % Setup ID.
            [idTool, temp] = obj.setupID(start, final, results, load, settings);
            
            % Run ID.
            idTool.run();
            
            % Delete temp file.
            delete(temp);    
        end
        
        % varargin format: start, final, results, load, settings
        function runRRA(obj, varargin)
            
            if obj.computed.rra
                error('RRA already computed or provided.');
            elseif ~obj.computed.ik
                error('Require IK to compute RRA.');
            end
            
            [start, final, results, load, settings] = ...
                obj.parseDynamicArgs('RRA', varargin);
            
            % Modify pelvis COM in actuators file.
            obj.modifyPelvisCOM(settings);
            
            % Import OpenSim RRATool class.
            import org.opensim.modeling.RRATool
            
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
            rraTool.createExternalLoads('temp.xml', rraTool.getModel());
            delete('temp.xml');
            
            % Run RRA.
            rraTool.run()
        end
            
        % varargin format: start, final, results, load, settings
        function runAdjustmentRRA(obj, body, new_model, varargin)
            
            if obj.computed.rra
                error('RRA already computed or provided.');
            elseif ~obj.computed.ik
                error('Require IK to compute RRA.');
            end
            
            [start, final, results, load, settings] = ...
                obj.parseDynamicArgs('RRA', varargin);
            
            % Modify pelvis COM in actuators file.
            obj.modifyPelvisCOM(settings);
            
            % Import OpenSim RRATool class.
            import org.opensim.modeling.RRATool
            
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
            
            % Adjustment settings.
            rraTool.setAdjustCOMToReduceResiduals(true);
            rraTool.setAdjustedCOMBody(body);
            rraTool.setOutputModelFileName([results filesep new_model]);
            
            % Perform mass adjustments. 
            
            
            % Set external loads.
            ext = xmlread(load);
            ext.getElementsByTagName('datafile').item(0).getFirstChild. ...
                setNodeValue(obj.grfs_path);
            temp = [results filesep 'temp.xml'];
            xmlwrite(temp, ext);
            rraTool.createExternalLoads('temp.xml', rraTool.getModel());
            delete('temp.xml');
            
            % Run RRA.
            rraTool.run()
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
                    disp('No model adjustment.');
                case 6
                    disp('Adjusting COM according to specification.');
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
            elseif isa(Tool, 'org.opensim.modeling.CMCTool')
                Tool.setModelFilename(obj.model_path);
                Tool.loadModel([obj.default_cmc 'settings.xml']);
                Tool.addAnalysisSetToModel();
                Tool.updateModelForces(...
                    Tool.getModel(), [obj.default_cmc 'settings.xml']);
            else
                error('Unrecognized tool type.')
            end
        end
        
        % Set output directories, initial/final time and input files. 
        function setInputsAndOutputs(obj, Tool, initialTime, finalTime, dir)
            % Set results directory. 
            Tool.setResultsDir([obj.results_directory '/' dir]);
            
            % Slightly different behaviour for RRA vs ID. 
            if isa(Tool, 'org.opensim.modeling.RRATool') || ...
                    isa(Tool, 'org.opensim.modeling.CMCTool')
                Tool.setInitialTime(initialTime);
                Tool.setFinalTime(finalTime);
                Tool.setDesiredKinematicsFileName(obj.kinematics_path);
                
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
        
        % Performs the mass adjustments recommended by the RRA algorithm.
        function performMassAdjustments(obj, model, log)
            % Load the model. 
            import org.opensim.modeling.Model;
            osim = Model(getFullPath([model '.osim']));
            
            % Find the total mass change.
            mass = obj.getTotalMassChange(log);
            
            % Load the gait2392 mass proportion file. 
            proportions = Data(obj.gait2392_proportions);
            
            % Step through the bodies applying the correct mass changes.
            for i=1:size(proportions.Values,2)
                osim.getBodySet.get(proportions.Labels(1,i)).setMass(...
                    osim.getBodySet.get(proportions.Labels(1,i)).getMass() + ...
                    mass * proportions.Values(1,i));
            end
            
            osim.print([model '_mass_changed.osim']);
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
            
            if isa(Tool, 'org.opensim.modeling.RRATool') || ...
                    isa(Tool, 'org.opensim.modeling.CMCTool')
                Tool.createExternalLoads('temp.xml', Tool.getModel());
                delete('temp.xml');
            else
                error('Incorrect number of arguments to setupExternalLoads.');
            end
        end
        
        % Run the RRA algorithm.
        % 2 arguments: no adjustment.
        % 3 arguments: adjustment, from given time to end of IK file.
        % 4 arguments: adjustment, between given times. 
        function [RRA, adjusted_path] = runRRA(...
                obj, initialTime, finalTime, body, output)
            % Setup RRATool. Supports anywhere from 1 to 5 arguments. 
            % 1 - no adjustment, full file
            % 2 - no adjustment, from given time to end of file
            % 3 - either no adjustment, between given times OR
            %     with adjustment, full file
            % 4 - with adjustment, from given time to end of file
            % 5 - width adjustment, between given times.
            
            % Adjust the pelvis COM in the default RRA actuators file to
            % match the current model.
            obj.modifyPelvisCOM();
            
            % No mass adjustment. 
            if nargin == 1 || nargin == 2 || (nargin == 3 && ~isa(initialTime, 'char'))
                if nargin == 1
                    initialTime = obj.kinematics.Timesteps(1,1);
                    finalTime = obj.kinematics.Timesteps(end,1);
                elseif nargin == 2
                    finalTime = obj.kinematics.Timesteps(end,1);
                end
                
                dir = ['RRA_' 'load=' obj.load ...
                    '_time=' num2str(initialTime) '-' num2str(finalTime)];
                rraTool = obj.setupRRA(...
                            dir, initialTime, finalTime);
                rraTool.run()
                
                % Process resulting RRA data, only saving the result if 
                % necessary.
                if nargout == 1
                    RRA = RRAResults(obj, [obj.results_directory '/' dir '/RRA']);
                end
                
            % Mass adjustment. 
            elseif (nargin == 3 && isa(initialTime, 'char')) || nargin == 4 || nargin == 5
                if nargin == 3
                    body = initialTime;
                    output = finalTime; 
                    initialTime = obj.kinematics.Timesteps(1,1);
                    finalTime = obj.kinematics.Timesteps(end,1);
                elseif nargin == 4
                    % In this case finalTime is assumed to be excluded.
                    % Match the arguments accordingly. 
                    output = body;
                    body = finalTime;
                    
                    % Calculate the final time as the last frame of the
                    % kinematic data. 
                    finalTime = obj.kinematics.Timesteps(end,1);
                end
                    
                dir = ['RRA_' 'load=' obj.load ... 
                    '_time=' num2str(initialTime) '-' num2str(finalTime)...
                    '_withAdjustment'];
                rraTool = obj.setupRRA(...
                    dir, initialTime, finalTime, body, output);
                rraTool.run()
                    
                % Perform mass adjustment. 
                obj.performMassAdjustments([obj.results_directory '/' dir '/' output], getenv('EXOPT_OUT'));
                
                % Adjusted model path.
                adjusted_path = getFullPath([obj.results_directory filesep dir filesep output '_mass_changed.osim']);
                
                % Process resulting RRA data. 
                RRA = RRAResults(obj, [obj.results_directory '/' dir '/RRA'], ...
                    adjusted_path);
            else
                error('Incorrect number of arguments to runRRA');
            end
        end
        
        function cmc = setupCMC(obj, dir, startTime, endTime)
            % Import OpenSim CMCTool class.
            import org.opensim.modeling.CMCTool
            
            % Load default CMCTool.
            cmc = CMCTool([obj.default_cmc 'settings.xml']);
            
            % Perform setup.
            obj.loadModelAndActuators(cmc);
            obj.setInputsAndOutputs(cmc, startTime, endTime, dir);
            obj.setupExternalLoads(cmc);
        end
        
        function CMC = runCMC(obj, startTime, endTime)
            
            % If we just want to do it for the entire file.
            if nargin == 1
                startTime = obj.kinematics.Timesteps(1,1);
                endTime = obj.kinematics.Timesteps(end,1);
                
            % If only a start time is given.
            elseif nargin == 2
                endTime = obj.kinematics.Timesteps(end,1);
                
            % If we have both a start time and an end time.
            elseif nargin ~= 3
                error('Incorrect number of arguments to runCMC.');
            end
            
            dir = ['CMC_' 'load=' obj.load ...
                '_time=' num2str(startTime) '-' num2str(endTime)];
            
            cmc = obj.setupCMC(dir, startTime, endTime);
            
            cmc.run();
            
            % Process resulting CMC data if necessary.
            if nargout == 1
                CMC = CMCResults(...
                    [obj.results_directory '/' dir '/CMC'], obj);
            end
            
        end
    end
    
    methods (Access = private)
        
        function analyseInputKinematics(obj)
            [~, ~, ext] = fileparts(obj.kinematics_path);
            
            if strcmp(ext, '.mot')
                obj.computed.ik = true;
                obj.best_kinematics = obj.kinematics_path;
            elseif strcmp(ext, '.sto')
                obj.computed.ik = true;
                obj.computed.rra = true;
                obj.best_kinematics = obj.kinematics_path;
            elseif ~strcmp(ext, '.trc')
                error('Wrong file format for input kinematic data.');
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
                kinematics = Data(obj.best_kinematics);
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
            % Import OpenSim IKTool class.
            import org.opensim.modeling.InverseKinematicsTool;
            
            % Load IKTool.
            ikTool = InverseKinematicsTool(settings);
            
            % Assign parameters.
            model = Model(obj.model_path);
            ikTool.setModel(model);
            ikTool.setStartTime(start);
            ikTool.setEndTime(final);
            ikTool.setMarkerDataFileName(obj.best_kinematics);
            ikTool.setOutputMotionFileName(results);
        end
        
        function [idTool, temp] = ...
                setupID(obj, start, final, results, load, settings)
            % Import OpenSim IDTool class.
            import org.opensim.modeling.InverseDynamicsTool;
            
            % Load IDTool.
            idTool = InverseDynamicsTool(settings);
            
            % Assign parameters. 
            idTool.setModelFileName(obj.model_path);
            idTool.setResultsDir(results);
            idTool.setStartTime(start);
            idTool.setEndTime(final);
            idTool.setCoordinatesFilename(obj.best_kinematics);
            
            % Set external loads.
            ext = xmlread(load);
            ext.getElementsByTagName('datafile').item(0).getFirstChild. ...
                setNodeValue(obj.grfs_path);
            temp = [results filesep 'temp.xml'];
            xmlwrite(temp, ext);
            idTool.setExternalLoadsFilename(temp);
        end
        
        % Modify the pelvis COM in the default RRA_actuators file in order
        % to match the pelvis COM of the input model. 
        function modifyPelvisCOM(obj, settings)
            % Import OpenSim libraries & get default actuators file path.
            import org.opensim.modeling.Vec3
            
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
            obj.defaults.results.id = [obj.results_directory filesep 'ID'];
            obj.defaults.results.rra = [obj.results_directory filesep 'RRA'];
            obj.defaults.results.bk = [obj.results_directory filesep 'BK'];
            obj.defaults.results.cmc = [obj.results_directory filesep 'CMC'];
            
            % Set statuses to 0.
            obj.computed.ik = false;
            obj.computed.rra = false;
            obj.computed.bk = false;
            obj.computed.id = false;
            obj.computed.cmc = false;
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

