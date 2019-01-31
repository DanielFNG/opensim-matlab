function rot = rotx(angle)
% Return the rotation matrix for a rotation of angle about the x axis.

angle = degtorad(angle);
rot = [1, 0, 0; ...
    0, cos(angle), -sin(angle); ...
    0, sin(angle), cos(angle)];

end