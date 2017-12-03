%% recoverAPOMotorTorques description and strategy
% So, this script is going to be very similar to validateOptimisation.
% However, instead of using nominal APO torques, we will attempt to recover
% the actual APO torques which were recorded. To do this, the strategy is
% as follows:
%   - Consider a set of ASSISTED input data (kinematics, ground reaction
%   forces, a scaled model with the APO). 
%   - Using OpenSim, compute dynamically consistent joint kinematics (1) 
%   and dynamics (2) from just the ground reaction forces (i.e. net of APO 
%   and human).
%   - Consider the APO motor torques which were recorded from this trial
%   (3). 
%   - Use the linear APO force model to compute the spatial forces which
%   the APO is applying on the system.
%   - Using OpenSim again, this time considering both the APO forces and
%   the ground reaction forces, and using the dynamically consistent joint
%   angles (1), compute another set of joint torques (4).
%   - Run the optimisation, taking (4) to be the input data and (2) to be
%   the desired. Among the results will be a set of APO motor torques
%   calculated via the optimisation (5).
%   - Compare (3) and (5). The optimisation has already been validated
%   using nominal torques, so instead this should tell us about the
%   performance of the APO force model.

%% Some parameters.
system_model = 'apo.osim';
ik = 'ik.mot';
grf = 'grf.mot';
force_model = 'linear';
load_type_1 = 'normal';
load_type_2 = 'APO';
trial_directory_1 = 'ost_normal';
trial_directory_2 = 'ost_APO';
model_directory = 'jacobians';
apo_data = 'APO_data_right_StSt_EA2.mat';

%% Set up desired AKA the net torque case. 
% Construct an OpenSimTrial with only ground reaction forces.
trial = OpenSimTrial(...
    system_model, ik, load_type_1, grf, trial_directory_1);

% Run RRA.
rra = trial.runRRA();

% Construct a new OpenSimTrial using the RRA-corrected kinematics.
id_trial = OpenSimTrial(...
    system_model, rra.positions_path, load_type_1, grf, trial_directory_1);

% Run ID.
id = id_trial.runID();

% Use this to set up the desired.
des = Desired('match_id', 'all', id);

%% Set up exoskeleton and model.
apo = Exoskeleton('APO');
n = trial.human_dofs;
k = apo.Exo_dofs;
model = apo.constructExoskeletonForceModel(...
    rra, model_directory, force_model);

%% Set up APO torques.
% Load in APO data.
load(apo_data);

% Fill an annoying gap.
APO_data = zeros(112,5);
APO_data(1:17,1:end) = APO_data_copy2(28:44,1:end);
APO_data(18,1) = 0.44;
APO_data(18,2:end) = APO_data_copy2(44,2:end) ...
    + 0.5*(APO_data_copy2(46,2:end) - APO_data_copy2(44,2:end))/2;
APO_data(19,1) = 0.45;
APO_data(19,2:end) = APO_data_copy2(46,2:end) ...
    - 0.5*(APO_data_copy2(46,2:end) - APO_data_copy2(44,2:end))/2;
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

%% Set up input data aka taking the APO in to account. 
% Construct an OpenSimTrial using the RRA-corrected kinematics from the
% grf-only run, but the new grfs. 
id_APO_trial = OpenSimTrial(system_model, rra.positions_path, ...
    load_type_2, 'grf_withAPO.mot', trial_directory_2);

% Run ID.
id_APO = id_APO_trial.runID();

%% Run optimisation.
opt = Optimisation(id_APO, des, model);
OptResult = opt.run('LLSEE');