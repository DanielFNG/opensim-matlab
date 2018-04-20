names = fieldnames(Metrics);
for i=1:length(names)
    for j=2:2:10
        if Metrics.(names{i}).(['Context' num2str(j)]).diffs(3,6) < 0.05
            names{i}
            j
            (Metrics.(names{i}).(['Context' num2str(j)]).means(1,2) - Metrics.(names{i}).(['Context' num2str(j)]).means(1,3))/Metrics.(names{i}).(['Context' num2str(j)]).means(1,2)*100
        end
    end
end