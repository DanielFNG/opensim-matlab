% A script to process CMC, done separately since originally CMC was not
% part of the analysis chain.
root = 'F:\structs_with_metrics';
save_dir = 'F:\structs_with_cmc';

mkdir(save_dir);

%% Run CMCs.
subjects = 1;
feet = 1;
contexts = 2:2:10;
assistances = 1:3;

% Choose functions to execute.
handles = {@prepareBatchCMC};

% Process data, loading in existing structs. 
dataLoop(...
    root, subjects, feet, contexts, assistances, handles, save_dir, 1);