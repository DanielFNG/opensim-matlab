% This script deletes some of the unnecessary files that are created using
% CEINMS so as to free up space for more important files.

% Set root.

root = 'C:\Users\Daniel\University of Edinburgh\OneDrive - University of Edinburgh\Exoskeleton metrics data\Data files\';

for subject=2:8
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
        
        % Copy the static file we want in to the main path. 
        [copy_status, copy_msg] = copyfile([subject_path '/staticElaborations/Static1/Static1/Static1.trc'], [subject_path '/']);
        
        % Delete the rest of the staticElaborations folder. 
        del_status = 0;
        while del_status == 0
            [del_status, del_msg] = rmdir([subject_path '/staticElaborations'], 's');
        end
        
        % Loop over left and right foot. 
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
                
                delete([folder '/elaboration.xml']);
                delete([folder '/parameters.mat']);
                
                for assistance_level=1:3
                    if assistance_level == 1
                        % No APO.
                        ik_folder = [folder '\NE' num2str(i)];
                    elseif assistance_level == 2
                        % With APO, transparent.
                        ik_folder = [folder '\ET' num2str(i)];
                    elseif assistance_level == 3
                        % With APO, assisted. 
                        ik_folder = [folder '\EA' num2str(i)];
                    end
                    
                    % Delete the FilteredData folder. 
                    fdel_status = 0;
                    while fdel_status == 0
                        [fdel_status, fdel_msg] = rmdir([ik_folder '/FilteredData'], 's');
                    end
                end
            end
        end    
    end
end
