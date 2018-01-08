function [ Step_width ] = getStepWidth(Right_marker_pos, Left_marker_pos)
%CALCULATESTEPWIDTH
%   Finds the absolute distance between the right and left heel markers in
%   the z direction
    
Right_pos = Right_marker_pos.getDataCorrespondingToLabel('R_HeelZ');
Left_pos = Left_marker_pos.getDataCorrespondingToLabel('L_HeelZ');

Step_width = abs(Right_pos(1) - Left_pos(1));

end

