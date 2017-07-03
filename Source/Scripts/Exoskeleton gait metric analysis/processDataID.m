% Requires that the processDataRRA.m script has already been run.

% Create cell arrays to hold the results.
% ID_array follows the same indexing style as described in
% 'processDataIK.m'.
 ID_array{9,3,2,10} = {};

% Get the root folder.
root = ['C:\Users\Daniel\University of Edinburgh\OneDrive - University '...
    'of Edinburgh\Exoskeleton metrics data\Data files\'];

% Total number of ID's to perform. 
% 1680 IK results, only 1496 of which were processed using RRA.
total_ID = 1496;

% ID's performed so far.
current_ID = 0;

% Construct a loading bar.
h = waitbar(current_ID, 'Performing batch ID.');

% Loop over the nine subjects. 
for subject=1:8
    % Skip the missing data.
    if ~ (subject == 5)
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
        
        % Get the adjustment RRA folders.
        human_adjustment_rra = [subject_path '\dynamicElaborations\rightStSt\NE2\RRA_Results\adjustment'];
        APO_adjustment_rra = [subject_path '\dynamicElaborations\rightStSt\ET2\RRA_Results\adjustment'];

        % Find the inner RRA folder for the human model. 
        human_inner = dir(human_adjustment_rra);
        for index=1:size(human_inner,1)
            if (size(human_inner(index,1).name,2) > 7) && strcmp(human_inner(index,1).name(1:8),'RRA_load')
                human_inner_folder = [human_adjustment_rra '\' human_inner(index,1).name];
            end
        end

        % Find the inner RRA folder for the APO model.
        APO_inner = dir(APO_adjustment_rra);
        for index=1:size(APO_inner,1)
            if (size(APO_inner(index,1).name,2) > 7) && strcmp(APO_inner(index,1).name(1:8),'RRA_load')
                APO_inner_folder = [APO_adjustment_rra '\' APO_inner(index,1).name];
            end
        end

        % Get the adjusted model paths. 
        human_adjusted_model = [human_inner_folder '\model_adjusted_mass_changed.osim'];
        APO_adjusted_model = [APO_inner_folder '\model_adjusted_mass_changed.osim'];
        
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
                % Ignore varying height contexts.
                if (i ~= 3) && (i ~= 5)
                    % Filenames are different for steady state vs non steady state.
                    if mod(i,2) == 1
                        folder = [gait 'Non-StSt'];
                    else
                        folder = [gait 'StSt'];
                    end

                for assistance_level=1:3
                    % Get the IK and GRF folders.
                    if assistance_level == 1
                        % No APO.
                        grf_folder = [folder '\NE' num2str(i)];
                        % Change model and use IK if context is 3 or 5.
                        if i == 3 || i == 5
                            ik_folder = [folder '\NE' num2str(i) '\IK_Results'];
                            model = human_model;
                        else
                            ik_folder = [folder '\NE' num2str(i) '\RRA_Results'];
                            model = human_adjusted_model;
                        end
                    elseif assistance_level == 2
                        % With APO, transparent.
                        grf_folder = [folder '\ET' num2str(i)];
                        % Change model and use IK if context is 3 or 5.
                        if i == 3 || i == 5
                            ik_folder = [folder '\ET' num2str(i) '\IK_Results'];
                            model = APO_model;
                        else
                            ik_folder = [folder '\ET' num2str(i) '\RRA_Results'];
                            model = APO_adjusted_model;
                        end
                    elseif assistance_level == 3
                        % With APO, assisted.
                        grf_folder = [folder '\EA' num2str(i)];
                        % Change model and use IK if context is 3 or 5.
                        if i == 3 || i == 5
                            ik_folder = [folder '\EA' num2str(i) '\IK_Results'];
                            model = APO_model;
                        else
                            ik_folder = [folder '\EA' num2str(i) '\RRA_Results'];
                            model = APO_adjusted_model;
                        end
                    end

                        % Perform batch RRA.
                        ID_array{subject,assistance_level,j,i} = ...
                            runBatchID(model, ik_folder, grf_folder, [grf_folder '\ID_Results']);

                        % Update the loading bar.
                        if mod(i,2) == 1
                            current_ID = current_ID + 2;
                        else
                            current_ID = current_ID + 5;
                        end
                        waitbar(current_ID/total_ID);
                    end
                end
            end
        end
    end
end

% Close the loading bar.
close(h);

% Save the results to a Matlab save file. 
save([root 'Updated_ID_Results.mat'], 'ID_array', '-v7.3');
    