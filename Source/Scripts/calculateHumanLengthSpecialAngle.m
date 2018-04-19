function [human_length, special_angle] = ...
    calculateHumanLengthSpecialAngle(x, y, hip_angles, length)

% Create arrays of the right size. 
human_length = zeros(size(hip_angles));
special_angle = zeros(size(hip_angles));

a = asin(x/sqrt(x^2 + (length - y)^2));
c = pi/2 - hip_angles;
d = asin(y/sqrt(x^2 + y^2));
e = asin((sqrt(x^2 + y^2)*sin(c + d))/length);

% If hip_angle == a.
condition = hip_angles == a;
special_angle(condition) = hip_angles(condition);
human_length(condition) = sqrt(x^2 + (length - y)^2);

% If hip_angle == 0.
condition = hip_angles == 0;
special_angle(condition) = asin(x/length);
human_length(condition) = sqrt(length^2 - x^2) - y;

% If hip angles are positive but less than a. 
condition = (0 < hip_angles) & (hip_angles < a);
special_angle(condition) = asin(x*sin(c(condition))/length);
human_length(condition) = length*sin(pi - e(condition) - c(condition) ...
    - d)./sin(c(condition) + d);

% If hip_angle > a.
condition = (hip_angles > a);
b = asin(((y + x*cot(hip_angles)).*sin(pi - hip_angles))/length);
special_angle(condition) = b(condition);
human_length(condition) = (x + length*cos(b(condition) + pi/2 - ...
    hip_angles(condition)))./sin(hip_angles(condition));

% If hip_angle < 0.
condition = (hip_angles < 0);
hip_angles = abs(hip_angles);
special_angle(condition) = asin(sqrt(x^2+y^2)*sin(pi/2 + hip_angles(condition) + asin(y/sqrt(x^2+y^2)))/length);
human_length(condition) = sqrt(x^2 + y^2)*sin(pi - pi/2 - hip_angles(condition) - asin(y/sqrt(x^2+y^2)) - special_angle(condition))./sin(special_angle(condition));
    
end