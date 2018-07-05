% startloc = 'F:\Dropbox\PhD\Exoskeleton Metrics';
startloc = 'D:\Dropbox\PhD\Exoskeleton Metrics Offsets Axial';
endloc = 'D:\Dropbox\PhD\Exoskeleton Metrics Compliant';

data_folder = 'dynamicElaborations\right';

subjects = [1:4, 6:8];
contexts = 2:2:10;

for subject = subjects
    
    for context = contexts
        
        % Copy GRFs.
        grf_files = dir([startloc filesep 'S' num2str(subject) filesep data_folder filesep 'EA' num2str(context) filesep '*.mot']);
        for i=1:length(grf_files)
            copyfile([startloc filesep 'S' num2str(subject) filesep data_folder filesep 'EA' num2str(context) filesep grf_files(i).name], [endloc filesep 'S' num2str(subject) filesep data_folder filesep 'EA' num2str(context) filesep grf_files(i).name]);
        end
    end
end

