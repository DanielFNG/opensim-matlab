% Check what CMC's still need to be done.
%root = 'D:\Dropbox\PhD\Exoskeleton Metrics';
root = 'F:\Dropbox\PhD\Exoskeleton Metrics';
%root = 'G:\Dropbox\PhD\Exoskeleton Metrics'

%% Run CMCs first to just generate the files. .
subjects = [1:4,6:8];
feet = 1;
contexts = 2:2:10;
assistances = 1:3;

% Choose functions to execute.
handles = {@prepareCMCFileNumbers};

% Process data, loading in existing structs. 
dataLoop(root, subjects, feet, contexts, assistances, handles);