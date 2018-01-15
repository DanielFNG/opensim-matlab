function result = calculateCoPD(foot, grfs, label)
% Calculate difference in CoP given grfs and the correct label and foot.

% Get CoP trajectory.
cop_traj = grfs.getDataCorrespondingToLabel(label);

% Find min and max in stance phase only. 
stance = isolateStancePhase(grfs, foot);
max_pk = max(cop(stance));
min_pk = min(cop(stance));

% Return result. 
result = max_pk - min_pk;