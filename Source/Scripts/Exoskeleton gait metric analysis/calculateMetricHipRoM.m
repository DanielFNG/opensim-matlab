
% root = 'C:\Users\Graham\SharePoint\GORDON Daniel\Exoskeleton metrics data\Data files\Exoskeleton metrics data\Data files\';
% 
% load ([root 'IK_Results.mat'])

% Loop over the nine subjects. 
for subject=1:8
    % Skip the missing data. 
    if ~ (subject == 5)
        
        % Loop over the three assistance levels. 
        for assistance_level=1:3
            
            % Loop over left and right
            for j = 1:2
            
                % Loop over the ten contexts. 
                for i=1:10  

                    if i == 1 || i == 2 || i == 4 || i == 6 || i == 8 || i == 10

                        % Loop over the five gait cycles for the relevant
                        % contexts
                        for k = 1:5
                           Hip_RoM_array{subject,assistance_level,j,i}{k} = ...
                           getHipRoM(IK_array{subject,assistance_level,j,i}{k},j); 
                        end

                    else

                        % Loop over the two gait cycles for the relevant
                        % contexts
                        for k = 1:2
                           Hip_RoM_array{subject,assistance_level,j,i}{k} = ...
                           getHipRoM(IK_array{subject,assistance_level,j,i}{k},j); 
                        end
                    end                    
                end
            end
        end      
    end
end

% Save the results to a Matlab save file.
% save([root 'Step_width_array.mat'], 'step_Width_array');