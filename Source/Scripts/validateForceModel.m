%% validateForceModel description and strategy
% This script is designed to validate that the APO force model is providing
% a passable approximation to the forces being applied by the device. To do
% this, the strategy is as follows:
%   - Compute the dynamically consistent joint torques for flat, unassisted
%   walking (1).
%   - Compute the dynamically consistent joint torques for the same subject
%   during flat, assisted walking, where the APO forces, computed using the
%   APO force model, have been provided as external forces. (2)
%   - Compare (1) and (2). Since in (2) the APO forces were explicitly
%   taken account, the remainder should be comparable to (1). Differences
%   are attributable to errors in the APO force model.

%% Some parameters.
%start_time = 0.76;
%end_time = 2.0;
force_model = 'linear';
load_type_1 = 'normal';
load_type_2 = 'APO';
trial_directory_1 = 'ost_normal';
trial_directory_2 = 'ost_APO_implicit';
trial_directory_3 = 'ost_APO_explicit';
model_directory = 'jacobians';
system_model = 'model_apo.osim';
ik = 'ik0.mot';
grf = 'grf0.mot';
ik_apo = 'ik1.mot';
grf_apo = 'grf1.mot';
data = 'APO_data_right_StSt_EA2.mat';

%% Construct the first set of data.
% Construct an OpenSimTrial with only ground reaction forces.
trial = OpenSimTrial(system_model, ik, load_type_1, grf, trial_directory_1);

% Run RRA.
rra = trial.runRRA();

% Construct a new OpenSimTrial using the RRA-corrected kinematics.
id_trial = OpenSimTrial(system_model, rra.positions_path, load_type_1, grf, trial_directory_1);

% Run ID.
id = id_trial.runID(); 

%% Run an RRA using the corresponding assisted trial. Implicit APO forces.
% Construct an OpenSim trial using ground reaction forces only.
assisted_trial = OpenSimTrial(system_model, ik_apo, load_type_1, grf_apo, trial_directory_2);

% Run RRA.
assisted_rra = assisted_trial.runRRA();

% Do an ID on this for comparison. 
id_assisted_trial = OpenSimTrial(system_model, assisted_rra.positions_path, load_type_1, grf_apo, trial_directory_2);

% Run ID.
id_assisted = id_assisted_trial.runID();

%% Set up exoskeleton and model.
apo = Exoskeleton('APO');
n = assisted_trial.human_dofs;
k = apo.Exo_dofs;
model = apo.constructExoskeletonForceModel(assisted_rra, model_directory, force_model);

%% Set up APO torques.
% Load in APO data.
load(data);

% Fill an annoying gap.
APO_data = zeros(112,5);
APO_data(1:17,1:end) = APO_data_copy2(28:44,1:end);
APO_data(18,1) = 0.44;
APO_data(18,2:end) = APO_data_copy2(44,2:end) + 0.5*(APO_data_copy2(46,2:end) - APO_data_copy2(44,2:end))/2;
APO_data(19,1) = 0.45;
APO_data(19,2:end) = APO_data_copy2(46,2:end) - 0.5*(APO_data_copy2(46,2:end) - APO_data_copy2(44,2:end))/2;
APO_data(20:end,1:end) = APO_data_copy2(46:138,1:end);

% Save the left and right motor torques to arrays. 
left_motor_torque = APO_data(1:end,5);
right_motor_torque = APO_data(1:end,3);
t = zeros(2,size(left_motor_torque,1));
t(1,1:end) = right_motor_torque(1:end,1);
t(2,1:end) = left_motor_torque(1:end,1);

% Calculate the spatial force resulting from these trajectories. 
spatial = model.calculateSpatialForcesFromTorqueTrajectory(t.');

% Create a new external forces data object, and write it to file. 
[ext, apo_only] = model.createExtForcesFileAPOSpecific(spatial);
ext.writeToFile('grf_withAPO.mot',1,1);
apo_only.writeToFile('grf_onlyAPO.mot',1,1);

%% Construct the second set of data. Explicit APO forces.

% OpenSimTrial with full forces. 
APO_trial = OpenSimTrial(system_model, ik_apo, load_type_2, 'grf_withAPO.mot', trial_directory_3);

% Run RRA.
APO_rra = APO_trial.runRRA();

% Construct a new OpenSimTrial using the RRA-corrected kinematics.
id_APO_trial = OpenSimTrial(system_model, APO_rra.positions_path, load_type_2, 'grf_withAPO.mot', trial_directory_3);

% Run ID.
id_APO = id_APO_trial.runID();