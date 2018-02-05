% This script sets out the full post-OpenSim processing pipeline for a
% single subject. By post-OpenSim I mean that it is assumed that every
% OpenSim analysis for the subject has been done and the files are present
% to be read in to Matlab. 

root = 'F:\Dropbox\PhD\Exoskeleton Metrics';
save_dir = 'F:\one_subject_pipeline';

%% Load non-CMC data from file. 

% Choose data to look at.
subjects = 1;  % Ignore missing data from subject 5.
feet = 1:2;
contexts = 2:2:10;  % Only steady-state contexts for now.
assistances = 1:3;

% % Data loading.
% handles = {@prepareGRFFromFile, @prepareIKFromFile, @prepareRRAFromFile,...
%     @prepareIDFromFile, @prepareBodyKinematicsFromFile};
% 
% % Process data.
% dataLoop(...
%     root, subjects, feet, contexts, assistances, handles, save_dir);

%% Calculate spatial metrics. 

% % Handles. 
% handles = {@prepareCoMD, @prepareCoPD, @prepareHipPkT, @prepareHipROM, ...
%     @prepareMoS, @prepareSF, @prepareSW};
% 
% % Process data. Note how we now load from the save dir.
% dataLoop(...
%     root, subjects, feet, contexts, assistances, handles, save_dir, save_dir);

% %% Load CMC data from file.
% feet = 1;
% assistances = 1;
% handles = {@prepareCMCFromFile};
% 
% % Process data.
% dataLoop(...
%     root, subjects, feet, contexts, assistances, handles, save_dir, save_dir);

%% Calculate metabolics metrics.

% Restrict to one foot.
feet = 1;
assistances = 1;

% Handles.
handles = {@prepareAvgMusclePowers, @prepareAvgJointPowers};

% Process data, again loading and saving from same dir.
dataLoop(...
    root, subjects, feet, contexts, assistances, handles, save_dir, save_dir);

