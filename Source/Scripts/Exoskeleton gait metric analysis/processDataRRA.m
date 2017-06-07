% Requires that the processDataIK.m script has already been run. 

% Create cell arrays to hold the results.
% RRA_adjustments is indexed by the subject and then whether the model is
% with (2) or without (1) the APO.
% RRA_array follows the same indexing style as described in 'processDataIK.m'.
% RRA_adjustments{9,2} = {};
% RRA_array{9,3,2,10} = {};

% Get the root folder.
root = ['C:\Users\Daniel\University of Edinburgh\OneDrive - University '...
    'of Edinburgh\Exoskeleton metrics data\Data files\'];

% Total number of RRA's to perform.
% 1680 IK results. However, we ignore contexts 3 and 5. And we do an
% additional 16 adjustment RRA's (once per subject without APO, and once per
% subject with APO).
% 8*2*3*(3*2 + 5*5) + 16
total_RRA = 1504;

% RRA's performed so far.
current_RRA = 0;

% Construct a loading bar.
h = waitbar(current_RRA, 'Performing batch RRA with adjustment.');

% Loop over the nine subjects. 
for subject=7:7
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
        
        % Get the path for the scaled APO and no-APO models for this subject.
        human_model = [subject_path '\Scaling\no_APO.osim'];
        APO_model = [subject_path '\Scaling\APO.osim'];
        
        % First of all, do the adjustment RRA's for this subject. We need the IK
        % and GRF data corresponding to steady state flat walking (either 
        % leading foot is fine, we will arbitrarily take the right food) both
        % with and without the APO. We also arbitrarily take the first gait
        % cycle. 
        ik_no_APO = [subject_path ...
            '\dynamicElaborations\rightStSt\NE2\IK_Results\ik1.mot'];
        grf_no_APO = [subject_path ...
            '\dynamicElaborations\rightStSt\NE2\NE21.mot'];
        ik_APO = [subject_path ...
            '\dynamicElaborations\rightStSt\ET2\IK_Results\ik1.mot'];
        grf_APO = [subject_path ...
            '\dynamicElaborations\rightStSt\ET2\ET21.mot'];
        
        % Perform the adjustment RRA's.
        RRA_adjustments{subject,1} = adjustmentRRA(...
            human_model, ik_no_APO, grf_no_APO, ...
            [subject_path '\dynamicElaborations\rightStSt\NE2\RRA_Results']);
        RRA_adjustments{subject,2} = adjustmentRRA(...
            APO_model, ik_APO, grf_APO, ...
            [subject_path '\dynamicElaborations\rightStSt\ET2\RRA_Results']);
        
        % Update the loading bar post adjustment. 
        current_RRA = current_RRA + 2;
        waitbar(current_RRA/total_RRA);
        
        % Get the new model files for this subject before moving on to the
        % normal RRA's. 
        adjusted_model = RRA_adjustments{subject,1}.getAdjustedModel();
        adjusted_model_APO = RRA_adjustments{subject,2}.getAdjustedModel();
        
        % Loop over left/right gait cycles. 
        for j=1:1
            switch j
                case 1
                    gait = [subject_path '\dynamicElaborations\right'];
                case 2
                    gait = [subject_path '\dynamicElaborations\left'];
            end
            
            % Loop over the ten contexts. 
            for i=6:10 
                % Ignore contexts 3 and 5.
                if ~(subject == 3 || subject == 5)
                % Filenames are different for steady state vs non steady state.
                    if mod(i,2) == 1
                        folder = [gait 'Non-StSt'];
                    else
                        folder = [gait 'StSt'];
                    end

                    for assistance_level=1:3
                        % Get the IK and GRF folders. 
                        if assistance_level == 1
                            % No APO.
                            ik_folder = [folder '\NE' num2str(i) '\IK_Results'];
                            grf_folder = [folder '\NE' num2str(i)];
                            model = adjusted_model;
                        elseif assistance_level == 2
                            % With APO, transparent.
                            ik_folder = [folder '\ET' num2str(i) '\IK_Results'];
                            grf_folder = [folder '\ET' num2str(i)];
                            model = adjusted_model_APO;
                        elseif assistance_level == 3
                            % With APO, assisted. 
                            ik_folder = [folder '\EA' num2str(i) '\IK_Results'];
                            grf_folder = [folder '\EA' num2str(i)];
                            model = adjusted_model_APO;
                        end
                        
                        % Perform batch RRA. 
                        RRA_array{subject,assistance_level,j,i} = ...
                            runBatchRRA(model, ik_folder, grf_folder, [grf_folder '\RRA_Results']);
                        
                        % Update the loading bar.
                        if mod(i,2) == 1
                            current_RRA = current_RRA + 2;
                        else
                            current_RRA = current_RRA + 5;
                        end
                        waitbar(current_RRA/total_RRA);
                    end
                end
            end
        end
    end
end

% Close the loading bar.
close(h);

% Save the results to a Matlab save file. 
% save([root 'RRA_Results.mat'], 'RRA_array', 'RRA_adjustments');
