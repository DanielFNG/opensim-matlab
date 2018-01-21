function indices = isolateStancePhase(grf, label)
% Given grf data and a label pointing to to the correct vy force column for
% the foot in question, isolates the stance phase. 
    indices = find(grf.getDataCorrespondingToLabel(label) > 10);
end

