root = 'F:\Dropbox\PhD\Exoskeleton Metrics Offsets Axial';

subjects = [2:4, 6:8];
feet = 1;
contexts = 2:2:10;
assistances = 3;

handles = {@prepareOffsetGRFs};

dataLoop(root, subjects, feet, contexts, assistances, handles);