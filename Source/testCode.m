% This script checks that the new opensim-matlab implementation is working
% correctly, comparing the output of the new code to the old. 

new_ik = 'D:\Dropbox\PhD\results_for_testing_opensim-matlab2\new2\1\IK\ik.mot';
new_rra = 'D:\Dropbox\PhD\results_for_testing_opensim-matlab2\new2\1\RRA';
new_id = 'D:\Dropbox\PhD\results_for_testing_opensim-matlab2\new2\1\ID\id.sto';
new_bk = 'D:\Dropbox\PhD\results_for_testing_opensim-matlab2\new2\1\BK';
new_cmc = 'D:\Dropbox\PhD\results_for_testing_opensim-matlab2\new2\1\CMC';

old_ik = 'D:\Dropbox\PhD\Exoskeleton Metrics\S1\dynamicElaborations\right\NE2\IK_Results\ik1.mot';
old_rra = 'D:\Dropbox\PhD\Exoskeleton Metrics\S1\dynamicElaborations\right\NE2\RRA_Results\1\RRA_load=normal_time=0.03-1.21';
old_id = 'D:\Dropbox\PhD\Exoskeleton Metrics\S1\dynamicElaborations\right\NE2\ID_Results\1\ID_load=normal_time=0.03-1.21\id.sto';
old_bk = 'D:\Dropbox\PhD\Exoskeleton Metrics\S1\dynamicElaborations\right\NE2\BodyKinematics_Results\1';
old_cmc = 'D:\Dropbox\PhD\Exoskeleton Metrics\S1\dynamicElaborations\right\NE2\CMC_Results\1\CMC_load=normal_time=0.03-1.21';

% Compare single files. 
new = Data(new_ik);
old = Data(old_ik);

new.eqToTolerance(old, 1e-8)

new = Data(new_id);
old = Data(old_id);

new.eqToTolerance(old, 1e-8)

% Compare folders. 
news = {new_rra, new_bk, new_cmc};
olds = {old_rra, old_bk, old_cmc};

for i=1:length(news)
    news_files = dirNoDots(news{i});
    olds_files = dirNoDots(olds{i});
    for j=1:length(news_files)
        [~, ~, ext] = fileparts(news_files(j).name);
        if any(strcmp({'.mot', '.sto', '.trc'}, ext))
            new = Data([news{i} filesep news_files(j).name]);
            old = Data([olds{i} filesep olds_files(j).name]);
            new.eqToTolerance(old, 1e-5)
        end
    end
end

