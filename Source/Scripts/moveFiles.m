startloc = 'F:\Dropbox\PhD\Exoskeleton Metrics';
endloc = 'F:\Dropbox\PhD\Exoskeleton Metrics Offsets Axial';

scale_folder = 'Scaling';
data_folder = 'dynamicElaborations\right';

subjects = [1:4, 6, 7, 8];
contexts = 2:2:10;

for subject = subjects
    % Copy scaling folders.
    copyfile([startloc filesep 'S' num2str(subject) filesep scale_folder], [endloc filesep 'S' num2str(subject) filesep scale_folder]);
    
    for context = contexts
        % Make folder.
        mkdir([endloc filesep 'S' num2str(subject) filesep data_folder filesep 'EA' num2str(context)])
        
        % Copy GRFs.
        grf_files = dir([startloc filesep 'S' num2str(subject) filesep data_folder filesep 'EA' num2str(context) filesep '*.mot']);
        for i=1:length(grf_files)
            copyfile([startloc filesep 'S' num2str(subject) filesep data_folder filesep 'EA' num2str(context) filesep grf_files(i).name], [endloc filesep 'S' num2str(subject) filesep data_folder filesep 'EA' num2str(context) filesep grf_files(i).name]);
        end
        
        % Copy RRA folder. 
        copyfile([startloc filesep 'S' num2str(subject) filesep data_folder filesep 'EA' num2str(context) filesep 'RRA_Results'], [endloc filesep 'S' num2str(subject) filesep data_folder filesep 'EA' num2str(context) filesep 'RRA_Results']);
    end
end

