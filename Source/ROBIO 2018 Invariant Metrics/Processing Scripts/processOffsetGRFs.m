root = 'F:\Dropbox\PhD\Exoskeleton Metrics Offsets';

subjects = 7;
feet = 1;
contexts = 2:2:10;
assistances = 3;

handles = {@prepareOffsetGRFs};

dataLoop(root, subjects, feet, contexts, assistances, handles);