% Script to analyse the performance of the different optimisation
% techniques in terms of their prediction of the human torque. The desired
% used will be percentage reduction with a full constraint coefficient
% matrix.

%% Calculate predicted torques. 

% Set up results directories.
osim_dir = 'osim';
apo_osim_dir = 'apo_osim';
model_dir = 'force_model';
results_dir = 'results';

% Set up input data and parameters.
model = 'model_adjusted_mass_changed.osim';
ik = 'ik.mot';
grf = 'grf.mot';
load = 'normal';
load_apo = 'APO';
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
force_model = apo.constructExoskeletonForceModel(...
    LLSResult.OfflineController.ForceModel.RRA, model_dir, descriptor);

% Store the right (1) and left (2) APO motor torques.
t = zeros(2,size(LLSResult.OptimisationResult.MotorCommands(1:end,1),1));
t(1,1:end) = LLSResult.OptimisationResult.MotorCommands(1:end,1);
t(2,1:end) = LLSResult.OptimisationResult.MotorCommands(1:end,2);

% Calculate the spatial forces resulting from these trajectories. 
spatial = force_model.calculateSpatialForcesFromTorqueTrajectory(t.');

% Create a new external forces data object, and write it to file. 
[ext, ~] = force_model.createExtForcesFileAPOSpecific(spatial);
ext.writeToFile('grf_withAPO.mot',1,1);

% Create the trial for doing id.
id_APO_trial = OpenSimTrial(model, LLSResult.OfflineController.ForceModel.RRA.positions_path, load_apo, 'grf_withAPO.mot', apo_osim_dir);

% Run ID, i.e. calculate simulated human contribution. 
id_APO = id_APO_trial.runID();
