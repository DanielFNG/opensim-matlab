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
        default_cmc
        default_id
        default_ext
        gait2392_model
        gait2392_proportions
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
                if ~exist(results, 'dir')
                    mkdir(results);
                end
                obj.results_directory = results;
                [obj.default_rra, obj.default_cmc, obj.default_id, ...
                    obj.default_ext, obj.gait2392_model, ...
                    obj.gait2392_proportions] = obj.loadDefaults();
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
            elseif isa(Tool, 'org.opensim.modeling.CMCTool')
                Tool.setModelFilename(obj.model_path);
                Tool.loadModel([obj.default_cmc 'settings.xml']);
                Tool.addAnalysisSetToModel();
                Tool.updateModelForces(...
                    Tool.getModel(), [obj.default_cmc 'settings.xml']);
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
            if isa(Tool, 'org.opensim.modeling.RRATool') || ...
                    isa(Tool, 'org.opensim.modeling.CMCTool')
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
            
            if isa(Tool, 'org.opensim.modeling.InverseDynamicsTool')
                % Import Model class since InverseDynamicsTool doesn't have
                % a getModel method.
                import org.opensim.modeling.Model
                Tool.setExternalLoadsFileName(getFullPath('temp.xml'));
            elseif isa(Tool, 'org.opensim.modeling.RRATool') || ...
                    isa(Tool, 'org.opensim.modeling.CMCTool')
                Tool.createExternalLoads('temp.xml', Tool.getModel());
                delete('temp.xml');
            else
                error('Incorrect number of arguments to setupExternalLoads.');
            end
        end
        
        % Modify the pelvis COM in the default RRA_actuators file in order
        % to match the pelvis COM of the input model. 
        function modifyPelvisCOM(obj)
            % Import OpenSim libraries & get default actuators file path.
            import org.opensim.modeling.*
            actuators_path = [obj.default_rra 'gait2392_RRA_Actuators.xml'];
            
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
        
        % Run the ID algorithm. 
        function ID = runID(obj, startTime, endTime)
            
            % If we just want to do it for the entire file. 
            if nargin == 1
                startTime = obj.kinematics.Timesteps(1,1);
                endTime = obj.kinematics.Timesteps(end,1);
                
            % If only a start time is given. 
            elseif nargin == 2
                endTime = obj.kinematics.Timesteps(end,1);
            
            % If we have both a start time and an end time. 
            elseif nargin ~= 3
                error('Incorrect number of arguments to runID.');
            end
            
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
            
            % If required, create an IDResult object to store ID result. 
            if nargout == 1
                ID = IDResult(obj, [obj.results_directory '/' dir '/']);
            end
        end
    end
    
    methods(Static)
        
        % Load the filenames for default RRA, ID settings etc. 
        function [rra, cmc, id, ext, model, prop] = loadDefaults()
            rra = [getenv('EXOPT_HOME') '/Defaults/RRA/'];
            id = [getenv('EXOPT_HOME') '/Defaults/ID/'];
            cmc = [getenv('EXOPT_HOME') '/Defaults/CMC/'];
            ext = [getenv('EXOPT_HOME') '/Defaults/ExternalLoads/'];
            model = [getenv('EXOPT_HOME') '/Defaults/Model/gait2392.osim'];
            prop = [getenv('EXOPT_HOME') ...
                '/Defaults/Model/gait2392_mass_proportions.txt'];
        end
        
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
        
    end   
end

