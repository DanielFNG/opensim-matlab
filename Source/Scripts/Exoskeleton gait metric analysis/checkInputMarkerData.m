% Script to check the input marker data for NaN values i.e. due to missing
% markers that have snuck past the Vicon gap filling process.

% Get the root folder. 
root = ['C:\Users\Daniel\University of Edinburgh\OneDrive - University '...
    'of Edinburgh\Exoskeleton metrics data\Data files\'];

% Loop over the nine subjects. 
for subject=1:9
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
                
                % Get IK folders. 
                ik_folder{1} = [folder '\NE' num2str(i)];
                ik_folder{2} = [folder '\ET' num2str(i)];
                ik_folder{3} = [folder '\EA' num2str(i)];
                
                for k=1:3
                    trc_struct = dir([ik_folder{k} '/*.trc']);
                    for loop=1:size(trc_struct,1)
                        try
                            test = Data([ik_folder{k} '\' trc_struct(loop,1).name]);
                        catch ME
                            switch ME.identifier
                                case 'Data:NaNValues'
                                    warning('NaN values for subject %u, foot %u, context %u, assistance level %u., gait cycle %u', subject, j, i, k, loop);
                                otherwise
                                    rethrow(ME)
                            end
                        end
                    end
                end
            end
        end
    end
end