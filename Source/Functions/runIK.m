function [IK, InputMarkers, OutputMarkers] = runIK(model, input, results, append)
% Performs IK using default settings on given model and input data.
%   Takes model, input data and a results directory. Files are written to
%   the results directory and saved with the same name as the input file
%   but with a .mot extension. Results are also saved as a Data object.
%   Input data should be a trc file.
%
%   Based on the OpenSim BatchIK example available under the Apache
%   licence.

% Import the OpenSim modelling tools.
import org.opensim.modeling.*

% Initialise an InverseKinematicsTool using a default settings file. 
tool = InverseKinematicsTool([getenv('EXOPT_HOME') '\Defaults\IK\settings.xml']);

% Load and initialise the model, then tell the tool to use it.
model = Model(model);
model.initSystem();
tool.setModel(model);

% If the desired results directory does not exist, create it. 
if ~exist(results, 'dir')
    mkdir(results);
end

% Get the start and end time from the input data. 
markerData = Data(getFullPath(input));
initial_time = markerData.Timesteps(1,1);
final_time = markerData.Timesteps(end,1);

% Set the input, times and output for the tool.
output = [results '\ik' append '.mot'];
tool.setMarkerDataFileName(getFullPath(input));
tool.setStartTime(initial_time);
tool.setEndTime(final_time);
tool.setResultsDir([results '\' append 'MarkerData']);
tool.setOutputMotionFileName(output);

% Run IK.
tool.run();

% Copy the input marker data to the results folder.
copyfile(input, ...
    [results '\' append 'MarkerData\' 'raw_marker_locations.trc']);

% Interpret the results as Data objects if required.
if nargout ~= 0
    IK = Data(output);
    OutputMarkers = Data([results '\' append 'MarkerData' filesep ...
        'ik_model_marker_locations.sto']);
    InputMarkers = Data(input);
end

end

