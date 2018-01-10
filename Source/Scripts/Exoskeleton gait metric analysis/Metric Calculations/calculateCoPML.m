function result = getCoPML(subject_data, foot, context, assistance)
% Calculate CoPML in the medial-lateral direction.

% Isolate grfs.
grfs = subject_data.GRF{foot,context,assistance};

for i=1:vectorSize(cop)
    cop = grfs{i}.getDataCorrespondingToLabel(['    ground_force' num2str(foot) '_pz']);
    
    % Identify stance phase as the points with non-zero cop.
    % WARNING: ISN'T THERE AN EXTRA FEW FRAMES OF DATA AT THE END OF THE GRFS? CHECK WHEN BACK TO MAIN PC. 
    stance = find(cop ~= 0);
    max_pk = max(cop(stance(1):stance(end)));
    min_pk = min(cop(stance(1):stance(end)));
    result{i} = mak_pk - min_pk;
end

end 