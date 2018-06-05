function result = calculateCoMD(trajectories, label)
% Calculate difference in centre of mass given a body kinematics position
% trajectory and a label (corresponding to direction).

    com = 'center_of_mass_';

    com_traj = trajectories.getDataCorrespondingToLabel([com label]);
    result = max(com_traj) - min(com_traj);
end
    
    
