function [torque, force_par] = calculateModifiedTorque(...
    original_torque, special_angle, exo_length, human_length)

exo_force = abs(original_torque)/exo_length;
human_force = (sign(original_torque).*exo_force).*transpose(cos(special_angle));
force_par = transpose(exo_force).*sin(-special_angle);
torque = transpose(human_force).*human_length;

end