%% Obtain data directory. 

% Get the root folder using a UI.
root = uigetdir('', 'Select directory containing subject data folders.');

%% Preliminaries: required steps for RRA adjustment.
% 
% % Need to perform IK and adjustment RRA.
% handles = {@prepareBatchIK, @prepareAdjustmentRRA};
% 
% % Run for each subject, right foot, 2nd context, assistance levels 1 and 2. 
% subjects = [1:4, 6:8];
% feet = 1;
% contexts = 2;
% assistances = 1:2;
% 
% % Don't save anything at this stage, and clear the variable after running
% % to save memory. We just care about creating the adjusted model files 
% % required for full RRA and ID analyses. 
% dataLoop(root, subjects, feet, contexts, assistances, handles);

%% Full data processing pipeline. 

% Choose data to look at.  
subjects = [1:4, 6:8];  % Ignore missing data from subject 5.
feet = 1:2;
contexts = 2:2:10;  % Only steady-state contexts for now.
assistances = 1:3;
feet = 1;
contexts = 2:2:10;
assistances = 3;

% Choose functions to execute. 
%handles = {@prepareGRFFromFile, @prepareBatchIK, @prepareBatchRRA, ...
%    @prepareBatchID, @prepareBatchBodyKinematicsAnalysis};
handles = {@prepareBatchID};

% Choose periodic save destination.
save_dir = 'D:\with_apo_torques';

% Process data.
try
    dataLoop(root, subjects, feet, contexts, assistances, handles, save_dir);
catch ME
    fid = fopen('F:\Dropbox\PhD\Exoskeleton Metrics\Matlab Data Files\new_structs\error_message.txt', 'a+');
    fprintf(fid, '%s', ME.getReport('extended', 'hyperlinks', 'off'));
    rethrow(ME)
end
