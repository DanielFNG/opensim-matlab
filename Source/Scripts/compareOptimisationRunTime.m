% Script to analyse the runtime performance of the different optimisation
% techniques. This will be done for three types of desired: % reduction
% with some constraints (hip, knee, ankle); % reduction with a smaller set
% of constraints (hip only), and a full set of constraints using matchID.

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
flat_model_directory = 'jacobians_flat';

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
    system_model, ik_tilted, load_type, grf, tilted_directory);

% Run RRA.
tilted_rra = tilted.runRRA();

% Construct a new OpenSimTrial using the RRA_corrected kinematics.
tilted_id_trial = OpenSimTrial(system_model, ...
    tilted_rra.positions_path, load_type, grf, tilted_directory);

% Run ID.
tilted_id = tilted_id_trial.runID();

%% Set up the three desireds. 

% Percentage reduction multiplier.
multiplier = 0.5;

% Hip only. 
joints{1} = 'hip_flexion_r';
joints{2} = 'hip_flexion_l';
pred_des = Desired('percentage_reduction', joints, multiplier);

% Hip, knee and ankle.
med_joints{1} = 'hip_flexion_r';
med_joints{2} = 'hip_flexion_l';
med_joints{3} = 'knee_angle_r';
med_joints{4} = 'knee_angle_l';
med_joints{5} = 'ankle_angle_r';
med_joints{6} = 'ankle_angle_l';
med_des = Desired('percentage_reduction', med_joints, multiplier);

% MatchID.
match_des = Desired('match_id', 'all', id); 

%% Set up exoskeleton and model.
apo = Exoskeleton('APO');
model = apo.constructExoskeletonForceModel(...
    tilted_rra, model_directory, force_model);
flat_model = apo.constructExoskeletonForceModel(...
    rra, flat_model_directory, force_model);

%% Run the different optimisations. 
% LLS, LLSE, LLSEE, HQP.
% QPOasesNormal, QPOasesFast. 
% All of the above sparse, too, except HQP which doesn't have coding for sparse
% at the moment. So 11 in total. 

n_methods = 11;
n_desireds = 3;
n_trials = 10;

% MethodTimes{n_methods, n_desireds, n_trials} = {};
% MethodResults{n_methods, n_desireds, n_trials} = {};

for j=1:n_trials
    for i=1:3
        if i == 1
            opt = Optimisation(id, pred_des, flat_model);
        elseif i == 2
            opt = Optimisation(id, med_des, flat_model);
        else
            opt = Optimisation(tilted_id, match_des, model);
        end
        tic;
        MethodResults{1,i,j} = opt.run('LLS');
        MethodTimes{1,i,j} = toc;
        tic;
        MethodResults{2,i,j} = opt.run('LLS', 'sparse');
        MethodTimes{2,i,j} = toc;
        tic;
        MethodResults{3,i,j} = opt.run('LLSE');
        MethodTimes{3,i,j} = toc;
        tic;
        MethodResults{4,i,j} = opt.run('LLSE', 'sparse');
        MethodTimes{4,i,j} = toc;
        tic;
        MethodResults{5,i,j} = opt.run('LLSEE');
        MethodTimes{5,i,j} = toc;  
        tic;
        MethodResults{6,i,j} = opt.run('LLSEE', 'sparse');
        MethodTimes{6,i,j} = toc;
        tic;
        MethodResults{7,i,j} = opt.run('HQP');
        MethodTimes{7,i,j} = toc;
        tic;
        MethodResults{8,i,j} = opt.run('QPOases');
        MethodTimes{8,i,j} = toc;
        tic;
        MethodResults{9,i,j} = opt.run('QPOases', 'sparse');
        MethodTimes{9,i,j} = toc;
        tic;
        MethodResults{10,i,j} = opt.run('QPOases', 'fast');
        MethodTimes{10,i,j} = toc;
        tic;
        MethodResults{11,i,j} = opt.run('QPOases', 'sparse', 'fast');
        MethodTimes{11,i,j} = toc;
    end
end

%% Compute the averages.

average_times = zeros(n_methods,n_desireds);
for i=1:n_desireds
    for j=1:n_methods
        temp = 0;
        for k=1:n_trials
            temp = temp + MethodTimes{j,i,k};
        end
        average_times(j,i) = temp/n_trials;
    end
end

bar3(average_times);
