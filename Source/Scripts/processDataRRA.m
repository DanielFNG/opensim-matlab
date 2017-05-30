% Models (human).
human_model = 'C:\Users\Daniel\Dropbox\PhD Y1\Exo metrics data analysis\Data files\S1\17-05-18\Scaling\Scaled_no_APO.osim';

% Root.
root = 'C:\Users\Daniel\Dropbox\PhD Y1\Exo metrics data analysis\Data files\S1\17-05-18\dynamicElaborations\rightStSt\NE2';

[RRA_adjustment, RRA_array] = adjustAndRunBatchRRA(human_model, [root '\IK_Results\ik1.mot'], [root '\NE21.mot'], [root '\IK_Results'], root, [root '\RRA_Results']);

% Trying tilted.

% % Adjusted model. 
% adjusted_model = 'C:\Users\Daniel\Dropbox\PhD Y1\Exo metrics data analysis\Data files\S1\17-05-18\dynamicElaborations\rightStSt\NE2\RRA_Results\adjustment\RRA_load=normal_time=0.02-1.2_withAdjustment\model_adjusted_mass_changed.osim';
% 
% % Root.
% root = 'C:\Users\Daniel\Dropbox\PhD Y1\Exo metrics data analysis\Data files\S1\17-05-18\dynamicElaborations\rightStSt\NE4';
% 
% RRA_tilted_array = runBatchRRA(adjusted_model, [root '\IK_Results'], root, [root '\RRA_Results']);