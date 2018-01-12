%% Obtain data directory. 

% Get the root folder using a UI.
root = uigetdir('', 'Select directory containing subject data folders.');

% Subject specific data.
subject_leg = [0.93 0.93 0.91 0.9 0.97 0.97 0.94 0.95 0.92];

subject_speed = [0.95 0.95 0.94 0.94 0.98 0.98 0.96 0.97;...
    0.95 0.95 0.94 0.94 0.98 0.98 0.96 0.97;...
    0.95 0.95 0.94 0.94 0.98 0.98 0.96 0.97;...
    1.14 1.14 1.13 1.13 1.18 1.18 1.15 1.16;...
    0.76 0.76 0.75 0.75 0.78 0.78 0.77 0.78];

%% Preliminaries: required steps for RRA adjustment.

% Need to perform IK and adjustment RRA.
handles = {@prepareBatchIK, @prepareAdjustmentRRA};

% Run for each subject, right foot, 2nd context, assistance levels 1 and 2. 
subjects = [1:4, 6:8];
feet = 1;
contexts = 2;
assistances = 1:2;

% Don't save anything at this stage, and clear the variable after running
% to save memory. We just care about creating the adjusted model files 
% required for full RRA and ID analyses. 
prelim = dataLoop(root, subjects, feet, contexts, assistances, handles);
clear('prelim');

%% Full data processing pipeline. 

% Choose data to look at.  
subjects = [1:4, 6:8];  % Ignore missing data from subject 5.
feet = 1:2;
contexts = 2:2:10;  % Only steady-state contexts for now.
assistances = 1:3;

% Choose functions to execute. 
handles = {@prepareBatchIK, @prepareBatchRRA, @prepareBatchID, ...
    @prepareBatchBodyKinematicsAnalysis};

% Choose periodic save destination.
save_dir = 'C:\Users\Daniel\Documents\MatlabDataExoMetrics';

% Process data. 
result = dataLoop(root, subjects, feet, contexts, assistances, ...
    handles, save_dir);
