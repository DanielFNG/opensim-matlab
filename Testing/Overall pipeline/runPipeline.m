%% Updated implementation of inverse model.
% This script is for keeping track of the inverse model pipeline under the
% new framework of Exopt. Basically, going from the raw inputs that are
% required from the user, and ending up with optimisation results. I think
% I might eventually even have a class for this - it seems like it fits -
% but for now, and just to keep things straight, I'm going to work on this
% script. Also will be good to do some testing before moving ahead with the
% Optimisation side of things to make sure that everything's OK, especially
% with regards to time sync etc.
%
% Raw inputs: model file, kinematics file, external forces file.
%
% For now everything is going to be saved in the same directory as this
% script. 

%% Set up some parameters.

load_type = 'normal';
start_time = 0.5;
end_time = 1.0;
contact_settings = 'apo';

%% Create an OpenSimTrial for the inputs. 
% Get the input files.
[model,path] = uigetfile('*.osim', 'Select model file.');
model_path = [path model];
[kinematics,path] = uigetfile('*.mot', 'Select kinematics file.');
kinematics_path = [path kinematics];
[ext,path] = uigetfile('*.mot', 'Select external forces file.');
ext_path = [path ext];

% Get the absolute paths.
model_path = getFullPath(model_path);
kinematics_path = getFullPath(kinematics_path);
ext_path = getFullPath(ext_path);
% Construct OpenSimTrial. 
trial = OpenSimTrial(model_path, kinematics_path, ext_path, 'OST');

%% Perform RRA and Inverse Dynamics. 
% Do RRA on the OpenSimTrial. 
trial = trial.runRRA(load_type,start_time,end_time);

% Construct an OpenSimTrial based on the RRA kinematics. 
IDtrial = OpenSimTrial(model_path, trial.rra.positions_path, ext_path, 'ID');

% Run ID for this new trial.
IDtrial = IDtrial.runID(load_type,start_time,end_time);

%% Calculate the FrameJacobianSet from the RRA trial and contact settings.
fjs = FrameJacobianSet(trial,contact_settings,'FJS');


%% This is looking fine except for the ID result have 2 extra frames compared
% to the RRA result. Partially explained (1 frame) by the fact that in
% RRAData we delete a frame. But it seems RRA duplicates the last frame.
% Have to check this. I'm going to try implementing an OptimisationProblem
% class now - the set of equations and Optimisation variables. Because
% basically I'll have vector (matrix?) optimisation variables and matrices
% multiplying these. And I can base optimisation methods on this class.
% Probably won't implement LLS or LLSE, though. I'll do LLSEE and HQP
% later. 