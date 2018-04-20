startloc = 'D:\Dropbox\PhD\Exoskeleton Metrics';
endloc = 'D:\Dropbox\PhD\Exoskeleton Metrics Compliant';

scale_folder = 'Scaling';
data_folder = 'dynamicElaborations\right';

subjects = [1:4, 6:8];
contexts = 2:2:10;
assistances = 1:2;

for subject = subjects
    
    for assistance = assistances
        
        if assistance == 1
            ap = 'NE';
        else
            ap = 'ET';
        end
        
        for context = contexts
            
            % Copy the folder.
            copyfile([startloc filesep 'S' num2str(subject) filesep data_folder filesep ap num2str(context)], [endloc filesep 'S' num2str(subject) filesep data_folder filesep ap num2str(context)]);
        end
    end
end