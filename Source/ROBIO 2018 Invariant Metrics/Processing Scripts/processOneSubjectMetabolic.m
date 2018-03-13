% This script sets out the full processing pipeline for a single subject 
% for metabolics.

root = 'G:\Dropbox\PhD\Exoskeleton Metrics';
save_dir = 'F:\one_subject_pipeline_metabolic';

%% Load non-CMC data from file. 

% Choose data to look at.
subjects = 1;  % Ignore missing data from subject 5.
feet = 1;
contexts = 2:2:10;  % Only steady-state contexts for now.
assistances = 1:3;

% % Data loading.
% handles = {@prepareCMCFromFile};
% 
% % Process data.
% dataLoop(...
%     root, subjects, feet, contexts, assistances, handles, save_dir);

%% Calculate spatial metrics.

% Handles.
handles = {@prepareAvgJointPowers, @prepareAvgMusclePowers};

% Process data. Note how we now load from the save dir.
dataLoop(root, subjects, feet, contexts, assistances, handles, ...
    save_dir, save_dir);