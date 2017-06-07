function [ Hip_RoM ] = getHipRoM( IK , foot)
%GETHIPROM Summary of this function goes here
%   Detailed explanation goes here

switch foot
    case 1
        Hip_data = IK.getDataCorrespondingToLabel('hip_flexion_r');
        Hip_RoM = max(Hip_data) - min(Hip_data);
        
     case 2
        Hip_data = IK.getDataCorrespondingToLabel('hip_flexion_l');
        Hip_RoM = max(Hip_data) - min(Hip_data);
end

