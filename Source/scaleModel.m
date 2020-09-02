function scaleModel(...
    mass, output, static, settings, generic_model, generic_markers)

    base = 'C:\Users\danie\Documents\GitHub\opensim-matlab\Defaults\Scale';

    % Use default scale settings if none are provided.
    if nargin < 4
        settings = [base filesep 'settings.xml'];
    end
    
    % Use default generic model & markers if none are provided.
    if nargin < 6
        generic_model = [base filesep 'APO_2354_Metabolics.osim'];
        generic_markers = [base filesep 'APO_2354_Markers.xml'];
    end
    
    % Import OpenSim libraries
    import org.opensim.modeling.*
    
    % Create & load model and state.
    osim = Model(generic_model);
    state = osim.initSystem();
    
    % Create the time range array.
    static_data = Data(static);
    timesteps = static_data.Timesteps;
    time_array = ArrayDouble();
    time_array.set(0, timesteps(1));
    time_array.set(1, timesteps(end));
    
    % Create the tool
    scale_tool = ScaleTool(settings);
    
    % Adjust desired model mass.
    scale_tool.setSubjectMass(mass);
    
    % Access the generic model maker.
    model_maker = scale_tool.getGenericModelMaker();
    
    % Set the generic model & marker set.
    model_maker.setModelFileName(generic_model);
    model_maker.setMarkerSetFileName(generic_markers);
    
    % Access the model scaler.
    model_scaler = scale_tool.getModelScaler();
    
    % Set the input data and output model file.
    model_scaler.setMarkerFileName(static);
    model_scaler.setOutputModelFileName(output);
    model_scaler.setTimeRange(time_array);
    
    % Run model scaler.
    model_scaler.setPrintResultFiles(true);
    try
        model_scaler.processModel(osim, '', mass);
    catch
        pause(0.5);
        model_scaler.processModel(osim, '', mass);
    end
    
    % Load the newly scaled model.
    osim_scaled = Model(output);
    state = osim_scaled.initSystem();
    
    % Access the marker placer.
    marker_placer = scale_tool.getMarkerPlacer();
    
    % Set the input data for this stage.
    marker_placer.setStaticPoseFileName(static);
    marker_placer.setOutputModelFileName(output);
    marker_placer.setTimeRange(time_array);
    
    % Run marker placer.
    try
        marker_placer.processModel(osim_scaled);
    catch
        pause(0.5);
        marker_placer.processModel(osim_scaled);
    end

end