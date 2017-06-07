

%% Load in metric array
% root = 'C:\Users\Graham\Documents\MATLAB\MOtoNMS_v2_2\MyData\ElaboratedData';
% 
% load ([root 'IK_Results.mat'])

% metric = 'Step_Width';
% 
% A = load([ metric '_array']);
% B = fieldnames(A);
% A = A.(B{1});

A = Hip_RMSD_array;



%% Average over steady state gait cycles and subjects



 b = [];
% % Loop over the assistance levels.
for assistance_level=2:3
            
    % Loop over the five steady state contexts. 
    for i=[2 4 6 8 10]      
        for subject = [1:4 6:8]
            for j = 1:4
                b = [b A{subject,assistance_level,1,i}{j}];
                b = [b A{subject,assistance_level,2,i}{j}];
            end
        end
        
        Average_array(assistance_level,(i/2)) = mean(b);
        Stdev_array(assistance_level,(i/2)) = std(b);
        b = [];
    end
end
   
 Average_array = Average_array(2:3,:);
 Stdev_array = Stdev_array(2:3,:);    

%% Print array to appropriate folder

% metric = Average_array;

%% Convert to table


 
for i = 1:2
    for j = 1:5
         String_Av = num2str(Average_array(i,j),'%4.2f, '); 
         String_Stdev = num2str(Stdev_array(i,j),'%4.2f, ');
         Table(i,j) = {['$ ' String_Av ' \pm ' String_Stdev ' $']};
    end
end

  matrix = Table;
  rowLabels = {'row 1', 'row 2' , 'row 3'};
  columnLabels = {'col 1', 'col 2' , 'col 3' , 'col 4' , 'col 5'};
  matrix2latex(matrix, 'out.tex', 'rowLabels', rowLabels, 'columnLabels', columnLabels, 'alignment', 'c', 'format', '%-6.2f', 'size', 'tiny');

%% Plot values
Metric_Label = ['Hip angle RMS (' char(176) ')'];

ThreeDBarWithErrorBars(Average_array,Stdev_array,Metric_Label)





