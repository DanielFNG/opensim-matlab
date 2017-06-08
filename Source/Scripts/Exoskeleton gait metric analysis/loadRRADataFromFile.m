% Script to load the RRA_array results by reading in RRA files
% and save these to a Matlab save file for future use. I won't do the RRA
% adjustments array just for simplicity.

% Create cell array to hold results.
% RRA_array{9,3,2,10} = {};

% Create a temporary storage directory to be used as the Trial results
% folder.
results = ['C:\Users\Daniel\University of Edinburgh\OneDrive - University '...
    'of Edinburgh\Exoskeleton metrics data\Storage'];

% Get the root folder.
root = ['C:\Users\Daniel\University of Edinburgh\OneDrive - University '...
    'of Edinburgh\Exoskeleton metrics data\Data files\'];

% Loop over the eight subjects. 
for subject=6:8
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
            % Filenames are different for steady state vs non steady state.
            if mod(i,2) == 1
                folder = [gait 'Non-StSt'];
            else
                folder = [gait 'StSt'];
            end
            
            % Get RRA folders.
            rra_folder{1} = [folder '\NE' num2str(i) '\RRA_Results'];
            rra_folder{2} = [folder '\ET' num2str(i) '\RRA_Results'];
            rra_folder{3} = [folder '\EA' num2str(i) '\RRA_Results'];
            
            % Get IK folders for the trial.
            ik_folder{1} = [folder '\NE' num2str(i) '\IK_Results'];
            ik_folder{2} = [folder '\ET' num2str(i) '\IK_Results'];
            ik_folder{3} = [folder '\EA' num2str(i) '\IK_Results'];
            
            % Get the GRF folders for the trial. 
            grf_folder{1} = [folder '\NE' num2str(i)];
            grf_folder{2} = [folder '\ET' num2str(i)];
            grf_folder{3} = [folder '\EA' num2str(i)];
            
            for k=1:3
                
                if i == 1 || mod(i,2) == 0
                    expected_size = 5;
                else
                    expected_size = 2;
                end
                
                % Create an array to hold the inner RRA results.
                inner_rra_array = cell(1,expected_size);
                
                % Get the folder and file names. 
                trc_struct = dir(rra_folder{k});
                ik_struct = dir([ik_folder{k} '/*.mot']);
                grf_struct = dir([grf_folder{k} '/*.mot']);
                
                % Start looping from 3 to avoid the '.' and '..' folders.
                for loop=3:expected_size+2
                    % Construct the correct OpenSimTrial.
                    if k == 1
                        model = human_adjusted_model;
                    else
                        model = APO_adjusted_model;
                    end
                    trial = OpenSimTrial(human_adjusted_model, [ik_folder{k} '/' ik_struct(loop-2,1).name], 'normal', [grf_folder{k} '/' grf_struct(loop-2,1).name], results);

                    % Interpret the RRA data within each subfolder.
                    inside_rra_folder = dir([rra_folder{k} '\' num2str(loop-2)]);
                    inner_rra_array{1,loop-2} = RRAResults(trial, ...
                        [rra_folder{k} '\' num2str(loop-2) '\' inside_rra_folder(3,1).name '\RRA']);
                end
                
                % Add the inner rra result to the main RRA array.
                RRA_array{subject,k,j,i} = inner_rra_array;
                
                % Display output so we can see progress...
                warning('Subject %u, assistance level %u, foot %u, context %u', subject, k, j, i);
            end
        end
    end
    
    % Save the results in a separate file incase we run out of memory. 
    RRA_subject_array = RRA_array(subject,:,:,:);
    save([root ['RRA_Results_' int2str(subject) '.mat']], 'RRA_subject_array');
end

% Finally, if we don't run out of memory, save the entire thing.
save([root 'RRA_Results.mat'], 'RRA_array');
    