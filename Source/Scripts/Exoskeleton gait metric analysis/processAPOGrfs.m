root = 'F:\Dropbox\PhD\Exoskeleton Metrics';

subjects = 1;
feet = 1;
contexts = 2;
assistances = 3;

handles = {@createAPOGRFs};

save_dir = 'F:\apo_grfs';

dataLoop(root, subjects, feet, contexts, assistances, handles, save_dir);