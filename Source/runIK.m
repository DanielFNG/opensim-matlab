function success = runIK(model, markers, results, timerange, settings)

    % Create an IKTool from the supplied settings
    ik_tool = org.opensim.modeling.InverseKinematicsTool(settings);
    
    % Load & assign model
    osim = org.opensim.modeling.Model(model);
    osim.initSystem();
    ik_tool.setModel(osim);
    
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