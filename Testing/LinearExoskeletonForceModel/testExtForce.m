% Some parameters.
start_time = 0.0;
end_time = 0.2;
load_type = 'normal';
trial_directory = 'ost';
model_directory = 'efm';
force_model = 'linear';

% Construct OpenSimTrial.
trial = OpenSimTrial('testing_adjusted.osim', 'ik0.mot', load_type, 'grf0.mot', trial_directory);

% Run RRA.
rra = trial.runRRA(start_time, end_time); 

% Construct Exoskeleton.
apo = Exoskeleton('APO');

% Get Exoskeleton to construct LinearForceModel.
model = apo.constructExoskeletonForceModel(rra, model_directory, force_model);

% Construct some nominal trajectories for the APO motor torques. Out of
% phase sin-waves of amplitude 15. 
x = 0:2*pi/999:2*pi;
y = 15*sin(x);
z = 15*sin(x+pi);
t = zeros(2,size(x,2));
t(1,1:end) = y;
t(2,1:end) = z;

% Calculate the spatial forces resulting from these trajectories. 
spatial = model.calculateSpatialForcesFromTorqueTrajectory(t.');

% Create a new external forces file.
ext = model.createExtForcesFileAPOSpecific(spatial);

% Write it to file.
ext.writeToFile('testing_appending.txt',1,1);