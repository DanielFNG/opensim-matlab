function [ first ] = getFirstHeelStrike( Right_IK, Left_IK )
%GETFIRSTHEELSTRIKE Summary of this function goes here
%   Detailed explanation goes here

Right_start = getStartTime(Right_IK);
Left_start = getStartTime(Left_IK);

if Right_start < Left_start
    first = 1;
else
    first = 2;
end

