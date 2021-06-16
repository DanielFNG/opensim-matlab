function success = runIK(model, markers, results, settings, timerange)
% Run Inverse Kinematics in OpenSim. 
%
% A simplified interface which allows common parameters like time range,
% input model & input data to be changed in a single command.
%
%   model - path to an OpenSim model file
%   markers - path to a marker trajectory trc file
%   results - save directory
%   timerange - [t_0, t_1], where IK is computed for t_0 to t_1
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
    
    % Assign parameters
    ik_tool.setStartTime(timerange(1));
    ik_tool.setEndTime(timerange(2));
    ik_tool.setMarkerDataFileName(markers);
    if ~exist(results, 'dir')
        mkdir(results);
    end
    ik_tool.setResultsDir(results);
    ik_tool.setOutputMotionFileName([results filesep 'ik.mot']);

    % Run tool
    success = ik_tool.run();
    
end