function [torque, force_par] = calculateModifiedTorque(...
    original_torque, special_angle, exo_length, human_length)

exo_force = original_torque/exo_length;
human_force = exo_force.*transpose(cos(special_angle));
torque = human_force.*transpose(human_length);
force_par = -exo_force.*transpose(sin(special_angle));

end