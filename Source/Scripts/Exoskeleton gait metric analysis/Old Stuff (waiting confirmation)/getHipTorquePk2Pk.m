function [ Hip_torque_RoM ] = getHipTorquePk2Pk( ID , foot, subject, weight)
%GETHIPROM Summary of this function goes here
%   Detailed explanation goes here

switch foot
    case 1
        Hip_data = ID.getDataCorrespondingToLabel('hip_flexion_r_moment');
        Hip_torque_RoM = max(Hip_data) - min(Hip_data);
        Hip_torque_RoM =  Hip_torque_RoM/weight(subject); 
        if Hip_torque_RoM > 200
            warning('about to error');
            error('error');
        end
        
     case 2
        Hip_data = ID.getDataCorrespondingToLabel('hip_flexion_l_moment');
        Hip_torque_RoM = max(Hip_data) - min(Hip_data);
        Hip_torque_RoM =  Hip_torque_RoM/weight(subject); 
        if Hip_torque_RoM > 200
            error('error');
        end
end

