function success = runAnalyse(...
    name, model, input, controls, results, settings, timerange)
% Run an analysis in OpenSim.
%
% A simplified interface which allows common parameters like time range,
% input model & input data to be changed in a single command.
%
%   model - path to an OpenSim model file
%   input - path to the input data
%   controls - (optional) path to control data, [] if not available
%   results - absolute path to the results folder
%   settings - an OpenSim settings file containing desired settings
%   timerange - [t_0, t_1], where analysis is computed for t_0 to t_1
%
% NOTE: the output acceleration data requires GRF forces or it will be
% useless, see here: https://github.com/opensim-org/opensim-core/issues/2782


    % Import OpenSim AnalyzeTool class and Model class.
    import org.opensim.modeling.AnalyzeTool;
    import org.opensim.modeling.Model;
    
    % Get timerange if not specified by user
    if nargin < 7
        input_data = Data(input);
        timerange = [input_data.Timesteps(1), input_data.Timesteps(end)];
    end

    % Load bkTool.
    bk_tool = AnalyzeTool(settings, false);
    
    % Rename
    bk_tool.setName(name);

    % Load & assign model.
    model = Model(model);
    model.initSystem();
    bk_tool.setModel(model);
    
    % Determine behaviour based on input file type
    [~, ~, ext] = fileparts(input);
    switch ext
        case '.mot'
            bk_tool.setStatesFileName('');
            bk_tool.setCoordinatesFileName(input);
        case '.sto'
            bk_tool.setStatesFileName(input);
            bk_tool.setCoordinatesFileName('');
    end

    % Assign parameters.
    bk_tool.setInitialTime(timerange(1));
    bk_tool.setFinalTime(timerange(2));
    bk_tool.setResultsDir(results);
    bk_tool.setLoadModelAndInput(true);  % Do we need this?
    
    % Optionally add controls as well
    if ~isempty(controls)
        bk_tool.setControlsFileName(controls);
    end

    % Run tool.
    success = bk_tool.run();
    
end
