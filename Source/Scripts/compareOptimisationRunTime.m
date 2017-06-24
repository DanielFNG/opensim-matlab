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

%% Run the different optimisations. 
LLSTime{3,10} = {};
LLSETime{3,10} = {};
LLSEETime{3,10} = {};
LLSEESparseTime{3,10} = {};
HQPTime{3,10} = {};
OASESTime{3,10} = {};
OASES_SparseTime{3,10} = {};
OASES_FastTime{3,10} = {};
OASES_FastAndSparseTime{3,10} = {};
for j=1:10
    for i=1:3
        if i == 1
            opt = Optimisation(tilted_id, pred_des, model);
        elseif i == 2
            opt = Optimisation(tilted_id, med_des, model);
        else
            opt = Optimisation(tilted_id, match_des, model);
        end
%         tic;
%         LLSResult = opt.run('LLS');
%         LLSTime{i,j} = toc;
%         tic;
%         LLSEResult = opt.run('LLSE');
%         LLSETime{i,j} = toc;
%         tic;
%         LLSEEResult = opt.run('LLSEE');
%         LLSEETime{i,j} = toc;
%         tic;
%         LLSEESparseResult = opt.run('LLSEESparse');
%         LLSEESparseTime{i,j} = toc;
        tic;
        HQPResult = opt.run('HQP');
        HQPTime{i,j} = toc;  
        tic;
        OASESResult = opt.run('LLS_OASES');
        OASESTime{i,j} = toc;
        tic;
        OASES_SparseResult = opt.run('LLS_OASES_SPARSE');
        OASES_SparseTime{i,j} = toc;
%         tic;
%         OASES_FastResult = opt.run('LLS_OASES_FAST');
%         OASES_FastTime{i,j} = toc;
%         tic;
%         OASES_FastAndSparseResult = opt.run('LLS_OASES_FAST_SPARSE');
%         OASES_FastAndSparseTime{i,j} = toc;
    end
end

%% Compute the averages.

averages = zeros(9,3);
lls_time = zeros(10,1);
llse_time = zeros(10,1);
llsee_time = zeros(10,1);
llsee_sparse_time = zeros(10,1);
hqp_time = zeros(10,1);
oases_time = zeros(10,1);
oases_sparse_time = zeros(10,1);
oases_fast_time = zeros(10,1);
oases_sparse_fast_time = zeros(10,1);
for i=1:3
    for j=1:10
        lls_time(j,1) = LLSTime{i,j};
        llse_time(j,1) = LLSETime{i,j};
        llsee_time(j,1) = LLSEETime{i,j};
        llsee_sparse_time(j,1) = LLSEESparseTime{i,j};
        hqp_time(j,1) = HQPTime{i,j};
        oases_time(j,1) = OASESTime{i,j};
        oases_sparse_time(j,1) = OASES_SparseTime{i,j};
        oases_fast_time(j,1) = OASES_FastTime{i,j};
        oases_sparse_fast_time(j,1) = OASES_FastAndSparseTime{i,j};
    end
    averages(1,i) = mean(lls_time);
    averages(2,i) = mean(llse_time);
    averages(3,i) = mean(llsee_time);
    averages(4,i) = mean(llsee_sparse_time);
    averages(5,i) = mean(hqp_time);
    averages(6,i) = mean(oases_time);
    averages(7,i) = mean(oases_sparse_time);
    averages(8,i) = mean(oases_fast_time);
    averages(9,i) = mean(oases_sparse_fast_time);
end
