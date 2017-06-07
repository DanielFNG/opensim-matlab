function [ HipRMSD ] = getHipRMSD( IK_assist , IK_NE, foot )
%Calculates the RMSD between the current gait cycle and the equivalent no
%exoskeleton gait cycle.

switch foot
    case 1
        IK_assist = IK_assist.getDataCorrespondingToLabel('hip_flexion_r');
        IK_NE = IK_NE.getDataCorrespondingToLabel('hip_flexion_r');
       
     case 2
        IK_assist = IK_assist.getDataCorrespondingToLabel('hip_flexion_l');
        IK_NE = IK_NE.getDataCorrespondingToLabel('hip_flexion_l');
end

% Normalise data
IK_assist = normaliseData(IK_assist);
IK_NE = normaliseData(IK_NE);

% Find difference between assistance and no assistance cases
Hip_diff = IK_assist - IK_NE;

 % RMS
 
 HipRMSD = rms(Hip_diff);

end

