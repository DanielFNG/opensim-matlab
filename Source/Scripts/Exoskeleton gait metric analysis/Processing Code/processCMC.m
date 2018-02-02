% A script to process CMC, done separately since originally CMC was not
% part of the analysis chain.
root = 'D:\Dropbox\PhD\Exoskeleton Metrics';

%% Run CMCs first to just generate the files. .
subjects = [2:4,6:8];
feet = 1;
contexts = 2:2:10;
assistances = 3;
subjects = 2;
contexts = 4;

% Choose functions to execute.
handles = {@prepareBatchCMC};

% Process data, loading in existing structs. 
dataLoop(root, subjects, feet, contexts, assistances, handles);