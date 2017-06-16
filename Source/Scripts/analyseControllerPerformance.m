% A script to analyse the overall performance of the controller. We use
% LLSEE since it has a good prediction accuracy and is one of the faster
% methods. We will supply the same 3 desireds as for the time trial, but
% this time we will be interested in how well the human torques are able to
% match the desired.
%% Some parameters. 
system_model = 'apo.osim';
ik = 'ik.mot';
ik_tilted = 'ik_tilted.mot';
grf = 'grf.mot';
grf_tilted = 'grf_tilted.mot';
force_model = 'linear';
load_type = 'normal';
trial_directory = 'ost_normal';
tilted_directory = 'ost_tilted';
model_directory = 'jacobians';
tilted_model_directory = 'jacobians_tilted';

%% Set up the input tilted trial and a flat trial to use as a desired.  

% First, set up the flat trial. 
trial = OpenSimTrial(system_model, ik, load_type, grf, trial_directory);

% Run RRA.
rra = trial.runRRA();

% Construct a new OpenSimTrial using the RRA_corrected kinematics.
id_trial = OpenSimTrial(...
    system_model, rra.positions_path, load_type, grf, trial_directory);

% Run ID.
id = id_trial.runID();

% Now, get a tilted trial set up. 
tilted = OpenSimTrial(...
    system_model, ik_tilted, load_type, grf_tilted, tilted_directory);

% Run RRA.
tilted_rra = tilted.runRRA();

% Construct a new OpenSimTrial using the RRA_corrected kinematics.
tilted_id_trial = OpenSimTrial(system_model, ...
    tilted_rra.positions_path, load_type, grf_tilted, tilted_directory);

% Run ID.
tilted_id = tilted_id_trial.runID();

%% Set up the three desireds. 

% Percentage reduction multiplier.
multiplier = 0.8;

% Hip only. 
joints{1} = 'hip_flexion_r';
joints{2} = 'hip_flexion_l';
pred_des = Desired('percentage_reduction', joints, multiplier);

% Hip, knee and ankle.
med_joints{1} = 'pelvis_tilt';
med_joints{2} = 'pelvis_list';
med_joints{3} = 'pelvis_rotation';
med_joints{4} = 'hip_flexion_r';
med_joints{5} = 'hip_flexion_l';
med_des = Desired('percentage_reduction', med_joints, ...
    [1,1,1,multiplier,multiplier]);

% MatchID.
match_des = Desired('match_id', 'all', id); 

%% Set up exoskeleton and model.
apo = Exoskeleton('APO');
model = apo.constructExoskeletonForceModel(...
    rra, model_directory, force_model);
tilted_model = apo.constructExoskeletonForceModel(...
    tilted_rra, tilted_model_directory, force_model);

%% Run LLSEE for each of the desireds. 

LLSEEResult{3} = {};
for i=1:3
    if i == 1
        opt = Optimisation(id, pred_des, model);
    elseif i == 2
        opt = Optimisation(id, med_des, model);
    elseif i == 3
        opt = Optimisation(tilted_id, match_des, tilted_model);
    end
    LLSEEResult{i} = opt.run('LLSEE');
end