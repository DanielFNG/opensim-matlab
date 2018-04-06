function [human_length, special_angle] = ...
    calculateHumanLengthSpecialAngle(x, y, hip_angle, length)

hip_angle = abs(hip_angle);

if hip_angle < 0.0001
    special_angle = asin(x/length);
else
    special_angle = ...
        asin(((y + x*cot(hip_angle)).*sin(pi - hip_angle))/length);
end

if hip_angle == 0
    human_length = sqrt(length^2 - x^2);
else
    human_length = ...
        (x + length*cos(special_angle + pi - hip_angle))./sin(hip_angle);
end

end