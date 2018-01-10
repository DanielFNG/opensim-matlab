
root = 'C:\Users\Graham\SharePoint\GORDON Daniel\Exoskeleton metrics data\Data files\';
% 
% load ([root 'IK_Results.mat'])

subject_leg = [0.93 0.93 0.91 0.9 0.97 0.97 0.94 0.95 0.92];

subject_speed = [0.95 0.95 0.94 0.94 0.98 0.98 0.96 0.97;...
    0.95 0.95 0.94 0.94 0.98 0.98 0.96 0.97;...
    0.95 0.95 0.94 0.94 0.98 0.98 0.96 0.97;...
    1.14 1.14 1.13 1.13 1.18 1.18 1.15 1.16;...
    0.76 0.76 0.75 0.75 0.78 0.78 0.77 0.78];

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
                        context_folder = [folder '\NE' num2str(i)];
                        file = ['\NE' num2str(i)];
                    elseif assistance_level == 2
                        % With APO, transparent.
                        context_folder = [folder '\ET' num2str(i)];
                        file = ['\ET' num2str(i)];
                    elseif assistance_level == 3
                        % With APO, assisted. 
                        context_folder = [folder '\EA' num2str(i)];
                        file = ['\EA' num2str(i)];
                    end
                    
                    if i == 2 || i == 4 || i == 6 || i == 8 || i == 10
                        
                        % Loop over the two gait cycles for the relevant
                        % contexts
                        for k = 1:5
                            
                           GRF = GRF_array{subject,assistance_level,j,i}{k};
                        
                           MoS_array{subject,assistance_level,j,i}{k} = ...
                           getMoS(Positions_array{subject,assistance_level,j,i}{k},...
                           Velocities_array{subject,assistance_level,j,i}{k},GRF,...
                           Input_Markers_array{subject,assistance_level,1,i}{k},j,subject,subject_leg,...
                           subject_speed(i/2,subject)); 
                        end
                        
                    elseif i == 7 || i == 9

                        % Loop over the two gait cycles for the relevant
                        % contexts
%                         for k = 1:2
%                                                      
%                            GRF = Data([context_folder file num2str(k) '.mot']);
%                        
%                            MoS_array{subject,assistance_level,j,i}{k} = ...
%                            getMoS(Positions_array{subject,assistance_level,j,i}{k},...
%                            Velocities_array{subject,assistance_level,j,i}{k},GRF,...
%                            Input_Markers_array{subject,assistance_level,1,i}{k},j,subject,subject_leg);  
%                         end
                    end
                end
            end
        end
    end
end



% Save the results to a Matlab save file.
% save([root 'Step_width_array.mat'], 'step_Width_array');