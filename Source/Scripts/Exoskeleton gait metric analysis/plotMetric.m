

%% Load in average and standard deviation metric array
Metric_Var_Name = 'Step_length';
Metric_Label = 'Step length (mm)';
units = 'mm';
% 
% root = 'C:\Users\Graham\Documents\MATLAB\MOtoNMS_v2_2\MyData\ElaboratedData';
% Av = load ([root 'Av_' Metric_Var_Name '.mat'])
% Stdev = load ([root 'Stdev_' metric '.mat'])


ThreeDBarWithErrorBars(Av,Stdev,Metric_Label)

