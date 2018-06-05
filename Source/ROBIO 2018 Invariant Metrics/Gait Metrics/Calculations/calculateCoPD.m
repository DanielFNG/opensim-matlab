function result = calculateCoPD(grfs, f_label, label)
% Calculate difference in CoP given grfs and the correct label and foot.

% Get CoP trajectory.
cop = grfs.getDataCorrespondingToLabel(label);

% Find min and max in stance phase only. 
stance = isolateStancePhase(grfs, f_label);
max_pk = max(cop(stance));
min_pk = min(cop(stance));

% Return result. 
result = max_pk - min_pk;