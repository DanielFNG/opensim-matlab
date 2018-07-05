function torques = applyReturn(...
    return_rate, absorbtion_rate, torques, loading_set, unloading_set)

for i=1:length(unloading_set)
    torque = torques(unloading_set{i});
    n_elements = length(torque);
    loading_area = trapz(loading_set{i}, torques(loading_set{i}));
    amount_to_return = ...
        loading_area/(1 - absorbtion_rate)*absorbtion_rate*return_rate;
    start_point = torque(1);
    end_point = torque(end);
    new_area = 0;
    mid_point = round(n_elements/2);
    mid_torque = torque(mid_point);
    original_area = trapz(unloading_set{i}, torque);
    while new_area < abs(original_area + amount_to_return)
        curve = fit([1, mid_point, length(torque)].', ...
            [start_point, mid_torque, end_point].', 'poly2');
        torque(1:end) = curve(1:length(torque));
        new_area = abs(trapz(unloading_set{i}, torque));
        mid_torque = mid_torque + 0.1*sign(original_area);
    end
    torques(unloading_set{i}) = torque;
end

    