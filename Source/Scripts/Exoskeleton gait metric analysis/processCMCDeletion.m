root = uigetdir('', 'Select directory containing subject data folders.');

% Choose data to look at.
subjects = [2:4, 6:8];
feet = 1;
contexts = 2:2:10;
assistances = 3;

handles = {@deleteOldForceData};

save_dir = 'D:\deleted_cmc_data';

dataLoop(root, subjects, feet, contexts, assistances, handles, save_dir);