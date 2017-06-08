% Script to analyse the performance of the different optimisation
% techniques in terms of their prediction of the human torque. The desired
% used will be percentage reduction with a full constraint coefficient
% matrix.

%% Calculate predicted torques. 

% Set up results directories.
osim_dir = 'osim';
results_dir = 'results';

% Set up input data and parameters.
model = 'model_adjusted_mass_changed.osim';
ik = 'ik.mot';
grf = 'grf.mot';
load = 'normal';
descriptor = 'linear';

% Load the exoskeleton.
apo = Exoskeleton('APO');

% Find the start and end time of the trial.
ik_data = Data(ik);
start_time = ik_data.getStartTime();
end_time = ik_data.getEndTime();

% Construct OpenSimTrial.
trial = OpenSimTrial(model, ik, load, grf, osim_dir);

% Set up the desired. 
joints{1} = 'hip_flexion_r';
joints{2} = 'hip_flexion_l';
multiplier = 0.5;
des = Desired('percentage_reduction',joints,multiplier);

% Set up the offline controller.
controller = OfflineController(trial, apo, descriptor, des, results_dir);

% Perform the optimisation using each of the optimisation methods. 
[LLSResult, controller] = controller.run('LLS', start_time, end_time);
[LLSEResult, controller] = controller.run('LLSE', start_time, end_time);
[LLSEEResult, controller] = controller.run('LLSEE', start_time, end_time);
[HQPResult, controller] = controller.run('HQP', start_time, end_time);

%% Compute the simulated human contribution.

% Compute the force model.
force_model = apo.constructExoskeletonForceModel