function [IK, InputMarkers, OutputMarkers] = runIK(model, input, results)
% Performs IK using default settings on given model and input data.
%   Takes model, input data and a results directory. Files are written to
%   the results directory and saved with the same name as the input file
%   but with a .mot extension. Results are also saved as a Data object.
%   Input data should be a trc file.
%
%   Based on the OpenSim BatchIK example available under the Apache
%   licence. 

% Interpret the input trc file.
InputMarkers = Data(input);

% Import the OpenSim modelling tools.
import org.opensim.modeling.*

% Initialise an InverseKinematicsTool using a default settings file. 
tool = InverseKinematicsTool([getenv('EXOPT_HOME') '\Defaults\IK\settings.xml']);

% Load and initialise the model, then tell the tool to use it.
model = Model(model);
model.initSystem();
tool.setModel(model);

% If the desired results directory exists already, get its full path. If
% not, create it and get its full path. 
if exist([pwd '/' results], 'dir')
    results = getFullPath(results);
else
    results = createUniqueDirectory(results);
end

% Get the start and end time from the input data. 
markerData = MarkerData(getFullPath(input));
initial_time = markerData.getStartFrameTime();
final_time = markerData.getLastFrameTime();

% Set the input, times and output for the tool.
output = [results '\ik.mot'];
tool.setMarkerDataFileName(getFullPath(input));
tool.setStartTime(initial_time);
tool.setEndTime(final_time);
tool.setResultsDir(results);
tool.setOutputMotionFileName(output);

% Run IK.
tool.run();

% Interpret the results as a Data object. 
IK = Data(output);

% Also interpret the marker trajectories as a Data object.
OutputMarkers = Data([results '\ik_model_marker_locations.sto']);

% Store the input file in the same as the output for posterity.
InputMarkers.writeToFile([results '\raw_marker_locations.trc'],1,0);

end

