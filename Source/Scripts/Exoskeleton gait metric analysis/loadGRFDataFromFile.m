% Script to load the GRF data by reading in the GRF files
% and save these to a Matlab save file for future use.

% Create cell array to hold results.
GRF_array{8,3,2,10} = {};

% Get the root folder.
root = ['C:\Users\Daniel\University of Edinburgh\OneDrive - University '...
    'of Edinburgh\Exoskeleton metrics data\Data files\'];

% Loop over the eight subjects. 
for subject=1:8
    % Miss out subject 5.
    if subject ~= 5
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
                
                % Get the GRF folders for the trial.
                grf_folder{1} = [folder '\NE' num2str(i)];
                grf_folder{2} = [folder '\ET' num2str(i)];
                grf_folder{3} = [folder '\EA' num2str(i)];
                
                for k=1:3
                    
                    % How many files do we expect.
                    if i == 1 || mod(i,2) == 0
                        expected_size = 5;
                    else
                        expected_size = 2;
                    end
                    
                    % Create a temporary cell array of the correct size.
                    temp_cell = cell(1,expected_size);
                    
                    % Get each individual grf file.
                    grf_struct = dir([grf_folder{k} '/*.mot']);
                    
                    % Interpret the grf data.
                    for loop=1:expected_size
                        temp_cell{loop} = Data([grf_folder{k} '\' grf_struct(loop,1).name]);
                    end
                    
                    % Assign the correct entry of the grf_array.
                    GRF_array{subject,k,j,i} = temp_cell;
                end
            end
        end
    end
end

% Finally, save.
save([root 'Updated_GRF_Data.mat'], 'GRF_array');
    