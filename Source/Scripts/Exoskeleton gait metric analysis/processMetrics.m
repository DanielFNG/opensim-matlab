%% Obtain data directory. 

% Get the root folder using a UI.
root = uigetdir('', 'Select directory containing subject data files.');

%% Calculate metrics

% Choose data to look at.
subjects = [1:4, 6:8];  % Ignore missing data from subject 5.
feet = 1:2;
contexts = 2:2:10;  % Only steady-state contexts for now.
assistances = 1:3;

% Choose functions to execute.
handles = ...;

% Choose periodic save destination.
save_dir = uigetdir('', 'Select a periodic save destination.');

% Process data.
result = dataLoop(root, subjects, feet, contexts, assistances, ...
    handles, save_dir);
