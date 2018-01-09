
% root = 'C:\Users\Graham\Documents\MATLAB\MOtoNMS_v2_2\MyData\ElaboratedData';
% 
% load ([root 'IK_Results.mat'])

% Loop over the nine subjects. 
for subject=1:8
    % Skip the missing data. 
    if ~ (subject == 5)
        
        % Loop over the three assistance levels. 
        for assistance_level=1:3
            
            % Loop over the ten contexts. 
            for i=1:10  
                
                if i == 1 || i == 2 || i == 4 || i == 6 || i == 8 || i == 10
                    
                    first = getFirstHeelStrike(Input_Markers_array{subject,assistance_level,1,i}{1}...
                    ,Input_Markers_array{subject,assistance_level,2,i}{1});
                    
                    if first == 1
                        for k = 1:4
                        % for the case where right is the first heelstrike
                        Step_Length_array{subject,assistance_level,2,i}{k} = getStepLength(Input_Markers_array{subject,assistance_level,1,i}{k},...
                        Input_Markers_array{subject,assistance_level,2,i}{k},first); %Send both L and R IK files to calculate step Length function}

                        Step_Length_array{subject,assistance_level,1,i}{k} = getStepLength(Input_Markers_array{subject,assistance_level,2,i}{k},...
                        Input_Markers_array{subject,assistance_level,1,i}{k+1},first+1); %Send both L and R IK files to calculate step Length function}
                        
                        end
                    
                    else
                        for k = 1:4
                         % for the case where left is the first heelstrike
                        Step_Length_array{subject,assistance_level,1,i}{k} = getStepLength(Input_Markers_array{subject,assistance_level,2,i}{k},...
                        Input_Markers_array{subject,assistance_level,1,i}{k},first); %Send both L and R IK files to calculate step Length function}

                        Step_Length_array{subject,assistance_level,2,i}{k} = getStepLength(Input_Markers_array{subject,assistance_level,1,i}{k},...
                        Input_Markers_array{subject,assistance_level,2,i}{k+1},first-1); %Send both L and R IK files to calculate step Length function}
                
                        end            
                    end
                    
                else
                    
                    % Loop over the two gait cycles for the relevant
                    % contexts
                    if first == 1
                        % for the case where right is the first heelstrike
                        k = 1;
                        Step_Length_array{subject,assistance_level,2,i}{1} = getStepLength(Input_Markers_array{subject,assistance_level,1,i}{k},...
                        Input_Markers_array{subject,assistance_level,2,i}{k},first); %Send both L and R IK files to calculate step Length function}

                        Step_Length_array{subject,assistance_level,1,i}{1} = getStepLength(Input_Markers_array{subject,assistance_level,2,i}{k},...
                        Input_Markers_array{subject,assistance_level,1,i}{k+1},first); %Send both L and R IK files to calculate step Length function}
                        
                        Step_Length_array{subject,assistance_level,2,i}{2} = getStepLength(Input_Markers_array{subject,assistance_level,1,i}{k+1},...
                        Input_Markers_array{subject,assistance_level,2,i}{k+1},first); %Send both L and R IK files to calculate step Length function}
                   
                    
                    else
                        k = 1;
                        % for the case where left is the first heelstrike
                        Step_Length_array{subject,assistance_level,1,i}{1} = getStepLength(Input_Markers_array{subject,assistance_level,2,i}{k},...
                        Input_Markers_array{subject,assistance_level,1,i}{k},first); %Send both L and R IK files to calculate step Length function}

                        Step_Length_array{subject,assistance_level,2,i}{1} = getStepLength(Input_Markers_array{subject,assistance_level,1,i}{k},...
                        Input_Markers_array{subject,assistance_level,2,i}{k+1},first); %Send both L and R IK files to calculate step Length function}
                        
                        Step_Length_array{subject,assistance_level,1,i}{2} = getStepLength(Input_Markers_array{subject,assistance_level,2,i}{k+1},...
                        Input_Markers_array{subject,assistance_level,1,i}{k+1},first); %Send both L and R IK files to calculate step Length function}
                
                           
                    end
                end                    
            end
        end      
    end
end