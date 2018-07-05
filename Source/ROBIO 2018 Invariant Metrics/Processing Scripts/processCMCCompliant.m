% A script to process CMC, done separately since originally CMC was not
% part of the analysis chain.
root = 'F:\Dropbox\PhD\Exoskeleton Metrics Compliant';

%% Run CMCs first to just generate the files. .
subjects = 1;
feet = 1;
contexts = 2:2:10;
assistances = 3;

% Choose functions to execute.
handles = {@prepareBatchCMC};

% Process data, loading in existing structs. 
dataLoop(root, subjects, feet, contexts, assistances, handles);

% Choose functions to execute.
handles = {@prepareCMCFromFile};

% Choose periodic save destination.
save_dir = 'F:\Dropbox\PhD\Exoskeleton Metrics Compliant\Results';

% Process data.
dataLoop(root, subjects, feet, contexts, assistances, handles, save_dir);

% Handles.
handles = {@prepareAvgJointPowers, @prepareAvgMusclePowers};

% Process data. Note how we now load from the save dir.
dataLoop(root, subjects, feet, contexts, assistances, handles, ...
    save_dir, save_dir);