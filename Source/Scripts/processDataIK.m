% Create cell arrays to hold the results.
% First index is the subject identifier, from 1-9 technically but not
% including 5 because we didn't get full data for this, but I'll still go from
% 1-9 since these are their subject numbers. 
% Second index is the type of assistance: 1 for no exo (NE), 2 for transparent
% (ET) and 3 for active (EA).
% Second index is left/right gait cycle. 1 for right, 2 for left.
% Third index is the number of gait cycles among the trials. (EA1, EA2
% etc). These are in the same order as they were recorded. So EA1 is
% nonstst, EA2 stst, etc.
IK_array{9,3,2,10} = {};
Input_Markers_array{9,3,2,10} = {};
Output_Markers_array{9,3,2,10} = {};

% Get the root folder. 
root = ['C:\Users\Daniel\University of Edinburgh\OneDrive - University '...
    'of Edinburgh\Exoskeleton metrics data\Data files\'];

% Loop over the nine subjects. 
for subject=1:9
    % Skip the missing data. 
    if ~ subject == 5
        % There are four dates which need to be represented in the path.
        if subject == 1 || subject == 3 || subject == 4
            date = '18';
        elseif subject == 2
            date = '16';
        elseif subject == 6
            date = '19';
        else
            date = '22';
        end
        
        % Get the path for this subject. 
        subject_path = [root 'S' num2str(subject) '\17-05-' date];

        % Get the path for the scaled APO and no-APO models for this subject.
        human_model = [subject_path '\Scaling\no_APO.osim'];
        APO_model = [subject_path '\Scaling\APO.osim'];

        % Loop over left/right gait cycles. 
        for j=1:2
            switch j
                case 1
                    gait = [subject_path '\dynamicElaborations\right'];
                case 2
                    gait = [subject_path '\dynamicElaborations\left'];
            end
            
            % Loop over the ten contexts. 
            for i=1:10  
                % Filenames are different for steady state vs non steady state.
                if mod(i,2) == 1
                    folder = [gait 'Non-StSt'];
                else
                    folder = [gait 'StSt'];
                end

                % No APO
                ik_folder = [folder '\NE' num2str(i)];
                [IK_array{subject,1,j,i}, Input_Markers_array{subject,1,j,i},...
                    Output_Markers_array{subject,1,j,i}] = runBatchIK(...
                    human_model, ik_folder, [ik_folder '\IK_Results']);

                % With APO, transparent.
                ik_folder = [folder '\ET' num2str(i)];
                [IK_array{subject,2,j,i}, Input_Markers_array{subject,2,j,i},...
                    Output_Markers_array{subject,2,j,i}] = runBatchIK(...
                    APO_model, ik_folder, [ik_folder '\IK_Results']);

                % With APO, assisted.
                ik_folder = [folder '\EA' num2str(i)];
                [IK_array{subject,3,j,i}, Input_Markers_array{subject,3,j,i},...
                    Output_Markers_array{subject,3,j,i}] = runBatchIK(...
                    APO_model, ik_folder, [ik_folder '\IK_Results']);
            end
        end
    end
end

% Save the results to a Matlab save file.
save([root 'IK_Results.mat'], 'IK_array', 'Input_Markers_array', ... 
    'Output_Markers_array');

