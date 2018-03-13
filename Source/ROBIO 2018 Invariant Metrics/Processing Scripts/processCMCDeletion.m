root = 'F:\Dropbox\PhD\Exoskeleton Metrics';

% Choose data to look at.
subjects = [1:4, 6:8];
feet = 1;
contexts = 2:2:10;
assistances = 1:3;

handles = {@prepareDeleteCMCData};

dataLoop(root, subjects, feet, contexts, assistances, handles);