%% Generic parameters

home = getenv('OPENSIM_MATLAB_HOME');
root = [home filesep 'Tests'];

%% Generic tools

% Parameters
human_model = 'gait2392.osim';
input_model = 'model.osim';
adjusted_model = 'adjusted_model.osim';
markers = 'cycle01.trc';
grfs = 'cycle01.mot';
results = [root filesep 'Test Data'];

% Create initial ost
ost = OpenSimTrial(input_model, markers, results, grfs);

% Run initial IK
ost.run('IK');

% Perform model adjustment
ost.performModelAdjustment('torso', adjusted_model, human_model);

% Create new ost with corrected model
ost = OpenSimTrial(adjusted_model, markers, results, grfs);

% Run full OpenSim pipeline
ost.fullRun();


%% Modifying results & time range

% Parameters
times = [0.1 0.3];
savedir = [results filesep 'ReducedIK'];

% Run an additional IK on a portion of the data only
ost.run('IK', 'timerange', times, 'results', savedir)


%% Custom external loads

% Parameters
markers = 'apo01.trc';
grfs = 'apo01.mot';
load_file = [home filesep 'Defaults' filesep 'apo.xml'];

% Run up to inverse dynamics
ost = OpenSimTrial(adjusted_model, markers, results, grfs); 
ost.run('IK', 'results', [results filesep 'AssistedIK']);
ost.run('ID', 'results', [results filesep 'AssistedID'], 'load', load_file);
