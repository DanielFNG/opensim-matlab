function [torque, force_par] = calculateModifiedTorque(...
    original_torque, special_angle, exo_length, human_length)

exo_force = original_torque/exo_length;
human_force = transpose(exo_force).*cos(special_angle);
force_par = transpose(exo_force).*sin(special_angle);
torque = human_force.*human_length;

end