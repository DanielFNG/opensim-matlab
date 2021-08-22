function success = runIK(model, markers, folder, settings, timerange)
% Run Inverse Kinematics in OpenSim. 
%
% A simplified interface which allows common parameters like time range,
% input model & input data to be changed in a single command.
%
%   model - path to an OpenSim model file
%   markers - path to a marker trajectory trc file
%   output - path of output folder
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
    if ~isempty(folder)
        mkdir(folder);
    end
    
    % Assign parameters
    ik_tool.setStartTime(timerange(1));
    ik_tool.setEndTime(timerange(2));
    ik_tool.setMarkerDataFileName(markers);
    ik_tool.setResultsDir(folder);
    ik_tool.setOutputMotionFileName([folder filesep 'ik.mot']);

    % Run tool
    success = ik_tool.run();
    
end