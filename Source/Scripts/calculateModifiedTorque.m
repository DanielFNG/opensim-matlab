function result = calculateModifiedTorque(...
    original_torque, special_angle, exo_length, human_length)

exo_force = original_torque/exo_length;
human_force = exo_force.*cos(special_angle);
result = human_force.*human_length;

end