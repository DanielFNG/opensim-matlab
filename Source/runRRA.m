function success = runRRA(...
    model, input, grfs, results, load, body, output, settings, timerange)
% Run RRA in OpenSim.
%
% A simplified interface which allows common parameters like time range,
% input model & input data to be changed in a single command.
%
%   model - path to an OpenSim model file
%   input - path to the input data
%   grfs - path to external force data
%   results - path to the results folder
%   load - path to load descriptor XML file
%   body - body to be adjusted if correcting model, [] if not needed
%   output - path to desired output model file, [] if not needed
%   settings - an OpenSim settings file containing desired settings
%   timerange - [t_0, t_1], where BK is computed for t_0 to t_1

    % Temporarily copy RRA settings folder to new location.
    [folder, name, ext] = fileparts(settings);
    temp_folder = [results filesep 'temp'];
    copyfile(folder, temp_folder);
    settings = [temp_folder filesep name ext];

    % Import OpenSim rra_tool class.
    import org.opensim.modeling.rra_tool;

    % Get timerange if not specified by user
    if nargin < 9
        input_data = Data(input);
        timerange = [input_data.Timesteps(1), input_data.Timesteps(end)];
    end

    % Load rra_tool.
    rra_tool = rraTool(settings);

    % Modify pelvis COM in actuators file.
    actuators_path = char(rra_tool.getForceSetFiles().get(0));
    modifyPelvisCOM(model, actuators_path);

    % Assign parameters.
    rra_tool.setModelFilename(model);
    rra_tool.loadModel(settings);
    rra_tool.updateModelForces(rra_tool.getModel(), settings);
    rra_tool.setInitialTime(timerange(1));
    rra_tool.setFinalTime(timerange(2));
    rra_tool.setDesiredKinematicsFileName(input);
    rra_tool.setResultsDir(results);

    % Set external loads.
    ext = xmlread(load);
    ext.getElementsByTagName('datafile').item(0).getFirstChild. ...
        setNodeValue(grfs);
    temp_loads = [results filesep 'temp.xml'];
    xmlwrite(temp_loads, ext);
    rra_tool.createExternalLoads(temp_loads, rra_tool.getModel());
    
    % Adjustment specific settings
    if ~isempty(body)
        rra_tool.setAdjustCOMToReduceResiduals(true);
        rra_tool.setAdjustedCOMBody(body);
        rra_tool.setOutputModelFileName(output);
    end

    % Run tool.
    success = rra_tool.run();

    % File cleanup.
    OpenSimTrial.attemptDelete(temp_loads);
    OpenSimTrial.attemptDelete(temp_folder);
    
end