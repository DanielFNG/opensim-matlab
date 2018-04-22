context_names = {'Flat Walking', 'Uphill Walking', 'Downhill Walking', 'Fast Walking', 'Slow Walking'};

names = fieldnames(Metrics);
for j=2:2:10
    relevant_muscles = {};
    compliant_vals = [];
    offset_vals = [];
    n_muscles = 0;
    for i=1:length(names)
        if offsets.Metrics.(names{i}).(['Context' num2str(j)]).diffs(3,6) < 0.05 & compliant.Metrics.(names{i}).(['Context' num2str(j)]).diffs(3,6) < 0.05
            n_muscles = n_muscles + 1;
            relevant_muscles{n_muscles} = names{i};
            offset_vals = [offset_vals (offsets.Metrics.(names{i}).(['Context' num2str(j)]).means(1,2) - offsets.Metrics.(names{i}).(['Context' num2str(j)]).means(1,3))/offsets.Metrics.(names{i}).(['Context' num2str(j)]).means(1,2)*100];
            compliant_vals = [compliant_vals (compliant.Metrics.(names{i}).(['Context' num2str(j)]).means(1,2) - compliant.Metrics.(names{i}).(['Context' num2str(j)]).means(1,3))/compliant.Metrics.(names{i}).(['Context' num2str(j)]).means(1,2)*100];         
        elseif offsets.Metrics.(names{i}).(['Context' num2str(j)]).diffs(3,6) < 0.05
            n_muscles = n_muscles + 1;
            relevant_muscles{n_muscles} = names{i};
            offset_vals = [offset_vals (offsets.Metrics.(names{i}).(['Context' num2str(j)]).means(1,2) - offsets.Metrics.(names{i}).(['Context' num2str(j)]).means(1,3))/offsets.Metrics.(names{i}).(['Context' num2str(j)]).means(1,2)*100]; 
            compliant_vals = [compliant_vals 0];
        elseif compliant.Metrics.(names{i}).(['Context' num2str(j)]).diffs(3,6) < 0.05
            n_muscles = n_muscles + 1;
            offset_vals = [offset_vals 0];
            relevant_muscles{n_muscles} = names{i};
            compliant_vals = [compliant_vals (compliant.Metrics.(names{i}).(['Context' num2str(j)]).means(1,2) - compliant.Metrics.(names{i}).(['Context' num2str(j)]).means(1,3))/compliant.Metrics.(names{i}).(['Context' num2str(j)]).means(1,2)*100];
        end
    end
    if ~isempty(relevant_muscles)
        if length(relevant_muscles) > 1
            total_transparent_o = 0;
            total_active_o = 0;
            for k=1:length(relevant_muscles)
                if offset_vals(k) ~= 0
                    total_transparent_o = total_transparent_o + offsets.Metrics.(relevant_muscles{k}).(['Context' num2str(j)]).means(1,2);
                    total_active_o = total_active_o + offsets.Metrics.(relevant_muscles{k}).(['Context' num2str(j)]).means(1,3);
                end
            end
            total_transparent_c = 0;
            total_active_c = 0;
            for k=1:length(relevant_muscles)
                if compliant_vals(k) ~= 0
                    total_transparent_c = total_transparent_c + compliant.Metrics.(relevant_muscles{k}).(['Context' num2str(j)]).means(1,2);
                    total_active_c = total_active_c + compliant.Metrics.(relevant_muscles{k}).(['Context' num2str(j)]).means(1,3);
                end
            end
            total_o{j/2} = (total_transparent_o - total_active_o)/total_transparent_o * 100;
            total_c{j/2} = (total_transparent_c - total_active_c)/total_transparent_c * 100;
        end
        
        figure;
%         bar(compliant_vals, 'r');
%         hold on
%         bar(offset_vals);
        test = [offset_vals' compliant_vals'];
        b = bar(test);
        b(2).FaceColor = 'red';
        title(context_names{j/2}, 'FontSize', 20);
        xlabel('Muscle', 'FontSize', 20);
        ylabel('% decrease in metabolic energy consumption', 'FontSize', 20);
        for i=1:length(relevant_muscles)
            relevant_muscles{i} = convertHyphen(relevant_muscles{i});
        end
        set(gca, 'xticklabel', relevant_muscles);
        set(gca, 'FontSize', 20);
        xtickangle(45);
        x0=10;
        y0=10;
        width=800;
        height=550;
        set(gcf,'units','points','position',[x0,y0,width,height])
        legend('Ideal', 'Compliant');
    end
end