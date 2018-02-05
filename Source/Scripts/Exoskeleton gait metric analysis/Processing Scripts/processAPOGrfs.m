root = 'D:\Dropbox\PhD\Exoskeleton Metrics';

subjects = [1:4,6:7]; % 8 bugged out 
feet = 1;
contexts = 2:2:10;
assistances = 3;

subjects = 8;
feet = 1;
contexts = 2:2:10;
assistances = 3;

handles = {@prepareAPOGRFs};

save_dir = 'D:\apo_grfs';

dataLoop(root, subjects, feet, contexts, assistances, handles, save_dir);