function torques = applyAbsorbtion(...
    rate, torques, loading_set, unloading_set, leftover_set)

for i=1:length(loading_set)
    torque = torques(loading_set{i});
    if i ~= 1
        torque = torque - (torque(1) - endval);
    end
    diff = torque(2:end) - torque(1:end-1);
    diff = diff*(1 - rate);
    for j = 2:length(torque)
        torque(j) = torque(j-1) + diff(j-1);
    end
    torques(loading_set{i}) = torque;
    endval = torque(end);
    
    torque = torques(unloading_set{i});
    torque = torque - (torque(1) - endval);
    diff = torque(2:end) - torque(1:end-1);
    diff = diff*(1 - rate);
    for j = 2:length(torque)
        torque(j) = torque(j-1) + diff(j-1);
    end
    endval = torque(end);
    torques(unloading_set{i}) = torque;
    
    if i == 1 && ~isempty(leftover_set)
        torque = torques(leftover_set);
        torque = torque - (torque(1) - endval);
        diff = torque(2:end) - torque(1:end-1);
        diff = diff*(1-rate);
        for j=2:length(torque)
            torque(j) = torque(j-1) + diff(j-1);
        end
        endval = torque(end);
        torques(leftover_set) = torque;
    end
end

end