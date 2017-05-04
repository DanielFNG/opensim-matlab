%% Some parameters.
start_time = 0.0;
end_time = 1.5;
force_model = 'linear';
load_type_1 = 'normal';
load_type_2 = 'APO';
trial_directory_1 = 'ost_normal';
trial_directory_2 = 'ost_APO';
model_directory = 'jacobians';

%% Set up desired.
% Construct an OpenSimTrial with only ground reaction forces.
trial = OpenSimTrial('testing_adjusted.osim', 'ik0.mot', load_type_1, ...
    'grf0.mot', trial_directory_1);

% Run RRA.
rra = trial.runRRA(start_time, end_time);

% Construct a new OpenSimTrial using the RRA-corrected kinematics.
id_trial = OpenSimTrial('testing_adjusted.osim', rra.positions_path, ...
    load_type_1, 'grf0.mot', trial_directory_1);

% Run ID.
id = id_trial.runID(start_time, end_time);

%% Set up exoskeleton & model.
% Construct Exoskeleton and compute the force model.
apo = Exoskeleton('APO');
n = apo.Human_dofs;
k = apo.Exo_dofs;
model = apo.constructExoskeletonForceModel(rra, model_directory, force_model);

%% Set up nominal APO motor torques. 
% Construct some nominal trajectories for the APO motor torques. Out of
% phase sin waves of amplitude 15.
x = 0:2*pi/999:2*pi;
y = 15*sin(x);
z = 15*sin(x+pi);
t = zeros(2,size(x,2));
t(1,1:end) = y;
t(2,1:end) = z;

% Calculate the spatial force resulting from these trajectories.
spatial = model.calculateSpatialForcesFromTorqueTrajectory(t.');

% Create a new external forces data object, and write it to file.
[ext, apo_only] = model.createExtForcesFileAPOSpecific(spatial);
ext.writeToFile('grf_withAPO.mot',1,1);
apo_only.writeToFile('grf_onlyAPO.mot',1,1);

%% Set up input data. 
% Construct an OpenSimTrial with ground reaction forces and APO forces.
APO_trial = OpenSimTrial('testing_adjusted.osim', 'ik0.mot', load_type_2, ...
    'grf_withAPO.mot', trial_directory_2);

% This step is commented out because it is slightly incorrect! See below
% for details.
    % Run RRA.
    % rra_APO = APO_trial.runRRA(start_time, end_time);
 
    % Construct a new OpenSimTrial using the RRA-corrected kinematics.
    % id_APO_trial = OpenSimTrial('testing_adjusted.osim', rra_APO.positions_path, ...
    %     load_type_2, 'grf_withAPO.mot', trial_directory_2);

% Construct a new OpenSimTrial using the RRA-corrected kinematics, but from
% the GRF only run. It is important to do this so that both the input and the 
% desired ID profiles comes from the same input kinematics data.
% Additionally, using the APO force model to produce the RRA means there
% will be errors in the RRA result due to force model inaccuracy. This is
% not the case when doing RRA on just the grfs which are known accurately.
% The only downside is we end up with a net (exo + human) RRA, but this is
% irrelevant here. 
id_APO_trial = OpenSimTrial('testing_adjusted.osim', rra.positions_path, ...
    load_type_2, 'grf_withAPO.mot', trial_directory_2);

% Run ID.
id_APO = id_APO_trial.runID(start_time, end_time);

%% Run optimisation. 
timesteps = size(id_APO.id.Timesteps,1) - 20;
results = zeros(timesteps, 2*n + k);
for i=1:timesteps
    A = [zeros(n,k), zeros(n), eye(n)];
    b = id.id.Values(i,2:end).';
    C = [];
    d = [];
    P = model.P{i};
    Q = model.Q{i};
    E = [zeros(n,k), eye(n), eye(n); -P, eye(n), zeros(n)];
    f = [id_APO.id.Values(i,2:end).'; Q];
    
    results(i,1:end) = lsqlin(A,b,C,d,E,f);
end



















