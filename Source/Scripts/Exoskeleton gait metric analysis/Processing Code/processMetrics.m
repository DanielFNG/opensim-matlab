%% Obtain data directory. 

% Get the root folder using a UI.
%root = uigetdir('', 'Select directory containing subject data files.');
root = 'F:\updated_structs_cmc';

%% Calculate metrics

% Choose data to look at.
subjects = [1:4, 6:8];  % Ignore missing data from subject 5.
feet = 1:2;
contexts = 2:2:10;  % Only steady-state contexts for now.
assistances = 1:3;
feet = 1;

% Choose functions to execute.
handles = {@prepareCoMD, @prepareCoPD, @prepareHipPkT, @prepareHipROM, ...
    @prepareMoS, @prepareSF, @prepareAvgGroupPowers};

% DOES NOT INCLUDE SW ATM BECAUSE THIS INVOLVES 2 FEET!

% Choose periodic save destination.
%save_dir = uigetdir('', 'Select a periodic save destination.');
save_dir = 'F:\structs_with_metrics_cmc';

% Process data.
dataLoop(...
    root, subjects, feet, contexts, assistances, handles, save_dir, 1);
