function rot = roty(angle)
% Return the rotation matrix for a rotation of angle about the y axis.

angle = degtorad(angle);
rot = [cos(angle), 0, sin(angle); ...
    0, 1, 0; ...
    -sin(angle), 0, cos(angle)];
    
end