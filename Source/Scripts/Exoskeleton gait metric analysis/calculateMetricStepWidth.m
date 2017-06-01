

% Loop over the nine subjects. 
for subject=1:8
    % Skip the missing data. 
    if ~ (subject == 5)
        % There are four dates which need to be represented in the path.

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
                
                for assistance_level=1:3
                    if assistance_level == 1
                        % No APO.
                        ik_folder = [folder '\NE' num2str(i)];
                        model = human_model;
                    elseif assistance_level == 2
                        % With APO, transparent.
                        ik_folder = [folder '\ET' num2str(i)];
                        model = APO_model;
                    elseif assistance_level == 3
                        % With APO, assisted. 
                        ik_folder = [folder '\EA' num2str(i)];
                        model = APO_model;
                    end
                    [IK_array{subject,assistance_level,j,i}, ...
                    Input_Markers_array{subject,assistance_level,j,i},...
                    Output_Markers_array{subject,assistance_level,j,i}] ...
                        = runBatchIK(model, ik_folder, [ik_folder '\IK_Results']);
                    if mod(i,2) == 1
                        current_ik = current_ik + 2;
                    else
                        current_ik = current_ik + 5;
                    end
                    waitbar(current_ik/total_iks);
                end
            end
        end
    end
end