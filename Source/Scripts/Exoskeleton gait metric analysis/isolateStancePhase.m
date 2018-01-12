function indices = isolateStancePhase(grf, foot)
    indices = find(grf.getDataCorrespondingToLabel(...
        ['    ground_force' num2str(foot) '_vy']) > 10);
end

