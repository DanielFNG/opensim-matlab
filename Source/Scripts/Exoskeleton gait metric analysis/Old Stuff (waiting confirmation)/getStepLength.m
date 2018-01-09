function [ Step_length ] = getStepLength(First_foot_marker_pos, Second_foot_marker_pos, first)
%CALCULATESTEPlength Summary of this function goes here
%   Detailed explanation goes here
    
% Find the initial heel pos for the first foot contact


switch first

    case 1
        First_pos = First_foot_marker_pos.getDataCorrespondingToLabel('R_HeelX');
        Second_pos = Second_foot_marker_pos.getDataCorrespondingToLabel('L_HeelX');
    case 2
        First_pos = First_foot_marker_pos.getDataCorrespondingToLabel('L_HeelX');   
        Second_pos = Second_foot_marker_pos.getDataCorrespondingToLabel('R_HeelX');
end
        Second_start = getStartTime(Second_foot_marker_pos);
        timeColumn = First_foot_marker_pos.getTimeColumn();
        Belt_travel = First_pos(1) - First_pos(timeColumn==Second_start);
        Step_length = (Second_pos(1) - First_pos(1))+Belt_travel; 
