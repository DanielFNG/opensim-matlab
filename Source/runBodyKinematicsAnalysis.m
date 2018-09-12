function [Positions, Velocities, Accelerations] = ...
    runBodyKinematicsAnalysis(model, ik, results)
% Run a BodyKinematics analysis on IK data. 

% Import the OpenSim modelling tools.
import org.opensim.modeling.*

% Initialise a BodyKinematics Analsysis.
tool = AnalyzeTool([getenv('EXOPT_HOME') '\Defaults\Analyse\bodykinematics.xml']);

% Load and initialise the model, then tell the tool to use it.
model = Model(model);
model.initSystem();
tool.setModel(model);

% If the desired results directory does not exist, create it. 
if ~exist(results, 'dir')
    mkdir(results);
end

% Get the start and end time from the input data. 
markerData = Data(getFullPath(ik));
initial_time = markerData.Timesteps(1,1);
final_time = markerData.Timesteps(end,1);

% Set the input, times and output for the tool.
tool.setCoordinatesFileName(getFullPath(ik));
tool.setInitialTime(initial_time);
tool.setFinalTime(final_time);
tool.setResultsDir(results);

tool.run();

if nargout == 3
    Positions = ...
        Data([results '\Analysis_BodyKinematics_pos_global.sto']);
    Velocities = ...
        Data([results '\Analysis_BodyKinematics_vel_global.sto']);
    Accelerations = ...
        Data([results '\Analysis_BodyKinematics_acc_global.sto']);
end

end

