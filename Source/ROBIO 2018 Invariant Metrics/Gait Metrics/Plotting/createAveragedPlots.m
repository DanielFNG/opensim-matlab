muscle_set = {'add_brev', 'add_long', 'add_mag1', 'psoas', 'glut_max1', ...
    'bifemlh', 'rect_fem', 'vas_med', 'med_gas', 'soleus'};
label_set = {'Add. brev.', 'Add. long.', 'Add. mag.', 'Psoas', ...
    'Glut. max.', 'Bifemlh', 'Rect. fem.', 'Vas. med.', 'Med. gas.', ...
    'Soleus'};

A_val_off = [];
A_val_com = [0];
A_label = {};
C_val_off = [];
C_val_com = [0];
C_label = {};
n_A_labels = 0;
n_C_labels = 0;

for i=1:length(muscle_set)
    
    offsets.Metrics.(muscle_set{i}).calcCombinedMeansAndSdevs();
    compliant.Metrics.(muscle_set{i}).calcCombinedMeansAndSdevs();
    if ~isempty(offsets.Metrics.(muscle_set{i}).sig_diffs_A)
        n_A_labels = n_A_labels + 1;
        A_val_off = [A_val_off offsets.Metrics.(muscle_set{i}).calcAbsCohensD('A') 0 0]; 
        A_val_com = [A_val_com compliant.Metrics.(muscle_set{i}).calcAbsCohensD('A') 0 0];
        A_label{n_A_labels} = label_set{i};
    end
    if ~isempty(offsets.Metrics.(muscle_set{i}).sig_diffs_C)
        n_C_labels = n_C_labels + 1;
        C_val_off = [C_val_off offsets.Metrics.(muscle_set{i}).calcAbsCohensD('C') 0 0];
        C_val_com = [C_val_com compliant.Metrics.(muscle_set{i}).calcAbsCohensD('C') 0 0];
        C_label{n_C_labels} = label_set{i};
    end
end

A_val_com(end) = [];
figure;
bar(A_val_off);
hold on
bar(A_val_com, 'r');
title('Assistance scenario averaged', 'FontSize', 20);
xlabel('Muscle', 'FontSize', 20);
ylabel('Cohen''s D', 'FontSize', 20);
set(gca, 'xlim', [0 length(A_val_off)], 'xtick', 1.5:3:length(A_val_off)+0.5);
set(gca, 'xticklabel', A_label);
set(gca, 'FontSize', 20);
xtickangle(45);
x0=10;
y0=10;
width=800;
height=550;
set(gcf,'units','points','position',[x0,y0,width,height])
legend('Ideal', 'Compliant')

C_val_com(end) = [];
figure;
bar(C_val_off);
hold on
bar(C_val_com, 'r');
title('Context averaged', 'FontSize', 20);
xlabel('Muscle', 'FontSize', 20);
ylabel('Cohen''s D', 'FontSize', 20);
set(gca, 'xlim', [0 length(C_val_off)], 'xtick', 1.5:3:length(C_val_off)+0.5);
set(gca, 'xticklabel', C_label);
set(gca, 'FontSize', 20);
xtickangle(45);
x0=10;
y0=10;
width=800;
height=550;
set(gcf,'units','points','position',[x0,y0,width,height])
legend('Ideal', 'Compliant');
