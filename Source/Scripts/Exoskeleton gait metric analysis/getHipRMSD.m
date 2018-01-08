function HipRMSD = getHipRMSD(IK_Assist, IK_NE, foot)
% Calculates the RMSD between the current gait cycle and the equivalent no
% exoskeleton gait cycle.

% Get the hip flexion joint trajectories. 
switch foot
    case 1
        foot_label = 'hip_flexion_r';
    case 2
        foot_label = 'hip_flexion_l';
end
IK_Assist = IK_Assist.getDataCorrespondingToLabel(foot_label);
IK_NE = IK_NE.getDataCorrespondingToLabel(foot_label);

% Normalise data - Graham's function
IK_Assist = normaliseData(IK_Assist);
IK_NE = normaliseData(IK_NE);

% % Normalise data - other function
% IK_Assist = stretchVector(IK_Assist, 100);
% IK_NE = stretchVector(IK_NE, 100);

% Find difference between assistance and no assistance cases
Hip_diff = IK_Assist - IK_NE;

% RMS 
HipRMSD = rms(Hip_diff);

end

