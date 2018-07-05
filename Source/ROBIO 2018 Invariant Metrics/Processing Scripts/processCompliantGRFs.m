root = 'D:\Dropbox\PhD\Exoskeleton Metrics Compliant';

subjects = [2:4, 6:8];
feet = 1;
contexts = 2:2:10;
assistances = 3;

handles = {@prepareCompliantGRFs};

dataLoop(root, subjects, feet, contexts, assistances, handles);