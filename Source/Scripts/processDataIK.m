% Models (human, APO). 
human_model = 'C:\Users\Daniel\Dropbox\PhD Y1\Exo metrics data analysis\Data files\S1\17-05-18\Scaling\Scaled_no_APO.osim';
APO_model = 'C:\Users\Daniel\Dropbox\PhD Y1\Exo metrics data analysis\Data files\S1\17-05-18\Scaling\Scaled_APO.osim';

% Create cell arrays to hold the results.
% First index is the type of assistance: 1 for no exo, 2 for transparent
% and 3 for active. 
% Second index is left/right gait cycle. 1 for right, 2 for left. 
% Third index is the number of gait cycles among the trials. (EA1, EA2
% etc). These are in the same order as they were recorded. So EA1 is
% nonstst, EA2 stst, etc. 
IK_array{3,2,10} = {};
Input_Markers_array{3,2,10} = {};
Output_Markers_array{3,2,10} = {};

for j=1:2
    % Root directory. Start with just trying right steady state data.
    switch j
        case 1
            root = 'C:\Users\Daniel\Dropbox\PhD Y1\Exo metrics data analysis\Data files\S1\17-05-18\Experimental data\dynamicElaborations\right';
        case 2
            root = 'C:\Users\Daniel\Dropbox\PhD Y1\Exo metrics data analysis\Data files\S1\17-05-18\Experimental data\dynamicElaborations\left';
    end
    for i=1:10  
        % Filenames are different for steady state vs non steady state.
        if mod(i,2) == 1
            folder = [root 'Non-StSt'];
        else
            folder = [root 'StSt'];
        end
        
        % No APO
        ik_folder = [folder '\NE' num2str(i)];
        [IK_array{1,j,i}, Input_Markers_array{1,j,i}, Output_Markers_array{1,j,i}] = ...
            runBatchIK(human_model, ik_folder, [ik_folder '\IK_Results']);
        
        % With APO, transparent.
        ik_folder = [folder '\ET' num2str(i)];
        [IK_array{2,j,i}, Input_Markers_array{2,j,i}, Output_Markers_array{2,j,i}] = ...
            runBatchIK(APO_model, ik_folder, [ik_folder '\IK_Results']);
        
        % With APO, assisted.
        ik_folder = [folder '\EA' num2str(i)];
        [IK_array{3,j,i}, Input_Markers_array{3,j,i}, Output_Markers_array{3,j,i}] = ...
            runBatchIK(APO_model, ik_folder, [ik_folder '\IK_Results']);
    end
end