% A script to test out changes to dataLoop, prepare functions, batch
% functions and the OpenSimTrial class. This should mean analyses can be
% formed without explicitly saving them as objects. Hopefully solving some
% memory problems. Going to test entire OpenSim analysis set for one 
% subject, context, foot, assistance sample. 

root = 'D:\Dropbox\PhD\Exoskeleton Metrics';

%% Run CMCs first to just generate the files. .
subjects = 8;
feet = 1;
contexts = 2;
assistances = 3;

% Choose functions to execute.
handles = {@prepareAPOGRFs, @prepareBatchIK, @prepareBatchRRA, ...
    @prepareBatchID, @prepareBatchBodyKinematicsAnalysis, ...
    @prepareBatchCMC};

% Process data, loading in existing structs. 
dataLoop(root, subjects, feet, contexts, assistances, handles);