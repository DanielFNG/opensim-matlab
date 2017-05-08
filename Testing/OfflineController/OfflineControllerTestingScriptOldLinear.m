% Choose a results directory.
dir = 'testing';

% Set up input data a.k.a the OpenSimTrial. 
startTime = 1.0;
endTime = 2.2; % low end time just for testing 
trial = OpenSimTrial('APO.osim', 'ik0.mot', 'grf0.mot', dir);
loadType = 'normal'; % Normal external loads e.g. just grfs. 

% Load the Exoskeleton information and specify a force model. 
apo = Exoskeleton('APO');
descriptor = 'old_linear';

% Set up the desired. 
joints{1} = 'hip_flexion_r';
joints{2} = 'hip_flexion_l';
multiplier = 0.5;
des = Desired('percentage_reduction',joints, multiplier);

% Set up the offline controller.
controller = OfflineController(trial, apo, descriptor, des, dir);

% Perform the optimisation using LLSEE.
[result, controller] = controller.runOptimisation('LLSEE', loadType, startTime, endTime);

% Plot results.
figure; 
plot(result.OptimisationResult.HumanContribution(1:end-40,7));
hold on;
plot(result.OfflineController.Desired.IDResult.id.Values(1:end-40,8));
figure;
plot(result.OptimisationResult.MotorCommands(1:end,1));