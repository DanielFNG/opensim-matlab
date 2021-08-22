function success = runIK(model, markers, output, settings, timerange)
% Run Inverse Kinematics in OpenSim. 
%
% A simplified interface which allows common parameters like time range,
% input model & input data to be changed in a single command.
%
%   model - path to an OpenSim model file
%   markers - path to a marker trajectory trc file
%   output - path of output file
%   timerange - optional [t_0, t_1], where IK is computed for t_0 to t_1
%               if not given, full timerange of markers file
%   settings - an OpenSim settings file containing desired settings

    % Create an IKTool from the supplied settings
    ik_tool = org.opensim.modeling.InverseKinematicsTool(settings);
    
    % Load & assign model
    osim = org.opensim.modeling.Model(model);
    osim.initSystem();
    ik_tool.setModel(osim);
    
    % Get timerange if not specified by user
    if nargin < 5
        input_data = Data(markers);
        timerange = [input_data.Timesteps(1), input_data.Timesteps(end)];
    end
    
    % Create results directory if needed
    [folder, ~, ~] = fileparts(output);
    if ~isempty(folder) && ~exist(folder, 'dir')
        mkdir(folder);
    end
    
    % Assign parameters
    ik_tool.setStartTime(timerange(1));
    ik_tool.setEndTime(timerange(2));
    ik_tool.setMarkerDataFileName(markers);
    ik_tool.setResultsDir(folder);
    ik_tool.setOutputMotionFileName(output);

    % Run tool
    success = ik_tool.run();
    
end