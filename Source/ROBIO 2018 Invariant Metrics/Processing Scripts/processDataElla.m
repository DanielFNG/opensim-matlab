%% Obtain data directory. 

% Get the root folder using a UI.
root = uigetdir('', 'Select directory containing subject data folders.');

%% Full data processing pipeline.

% Choose data to look at.  
subjects = 1;
feet = 1;
contexts = 2;  % Only steady-state contexts for now.
assistances = 1;

% Choose functions to execute. 
handles = {@prepareBatchIK, @prepareAdjustmentRRA, @prepareBatchRRA, ...
    @prepareBatchID, @prepareBatchBodyKinematicsAnalysis};

% Execute data loop. 
dataLoop(root, subjects, feet, contexts, assistances, handles);