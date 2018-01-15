%% Obtain data directory.

% Get the root folder using a UI.
root = uigetdir('', 'Select directory containing subject data folders.');

%% Load data from file.

% Choose data to look at.
subjects = [1:4, 6:8];
feet = 1:2;
contexts = 2:2:10;
assistances = 1:3;

% Choose functions to execute.
handles = {@prepareGRFFromFile, @prepareIKFromFile, @prepareRRAFromFile,...
    @prepareIDFromFile, @prepareBodyKinematicsFromFile};

% Choose periodic save destination.
save_dir = 'F:\Dropbox\PhD\Exoskeleton Metrics\Matlab Data Files\new_structs_loaded';

% Process data.
try
    dataLoop(root, subjects, feet, contexts, assistances, handles, save_dir);
catch ME
    fid = fopen('F:\Dropbox\PhD\Exoskeleton Metrics\Matlab Data Files\error_message.txt', 'a+');
    fprintf(fid, '%s', ME.getReport('extended', 'hyperlinks', 'off'));
    rethrow(ME)
end