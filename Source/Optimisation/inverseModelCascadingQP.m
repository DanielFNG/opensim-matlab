function inverseModelCascadingQP(pathToData, timesteps, multiplier)

%% Human-APO Inverse Model - lsqlin
% When a human walks with aid of an exoskeleton the torques at the joints
% can be considered as a composite of effort from the human and the effect
% of the exoskeleton. In other words, we have:
%
% $$ \tau_{net} = \tau_{human} + \tau_{APO}. $$
%
% This script attempts to identify the forces which the exoskeleton
% (currently the Active Pelvis Orthosis aka APO) needs to apply in order to
% drive the human torque contribution towards some desired quantity
% $\tau_{desired}$. Rather than using a QP, which was the strategy of 
% previous implementations, this method attempts to find a least squares 
% solution of the underdetermined system with inequality constraints to 
% represent bounds on the magnitude of the APO torques.
%
% Author: Daniel Gordon 

%% Inverse model parameters.
% These parameters represent the free parameters of the inverse model,
% which in this case are equivalent to the parameters of the model for the
% application of APO forces. Currently APO forces are modelled as a force
% applied from a wrench measured at the APO motors, which are seen as being
% connected to the wearers thigh by a link of known distance. 
%
% If the APO force model becomes more complicated more parameters can be
% added, or alternatively parameters can be altered to investigate changes.
% Note that, should link length be changed here, the Jacobian mappings
% corresponding to the APO forces would have to be recalculated.
%
% Currently the number of timesteps is hard-coded at 119 but later when 
% mexing this script with C++ this should be calculated during execution. 

link = 0.35;
%timesteps = 119; 

%% Import the data we need. 
% The required data to perform the optimization includes: the net internal
% generalised forces calculated from the OpenSIM C++ API using the 
% getGeneralisedForces scrips; the Jacobian mappings from the
% left/right APO contact points on to generalised forces; and the time
% indexed states of the system calculated from RRA.
%
% For the time being this data has been pre-calculated. However, ideally a
% later step would be to MEX the required C++ code so as to have a 'one
% click solution' which calculates the require data within this script. 

net_internal = importdata([pathToData, '/net_internal_values.txt']);
right_jacobian = importdata([pathToData, '/right_apo_jacobian.txt']);
left_jacobian = importdata([pathToData, '/left_apo_jacobian.txt']);
states = importdata([pathToData, '/subsampled_states.txt']);

%% Initialise time-invariant variables.
% Here we set up arrays to store the optimisation results and the error 
% at each time-step. 
%
% We also set up an array to store the spatial forces applied by the APO 
% given in the ground frame - these are calculated from the optimisation 
% results given the known APO contact Jacobians, and are necessary to write
% an external forces file which will later be used in OpenSim simulations.
% This array also stores the CoP of these external forces as measured in
% the hip joint frame. For simplicity, the fact that the APO 'pushes' on 
% the back of the leg and 'pulls' on the front of the leg is for the 
% time-being abstracted out to a single point of external force located in 
% the middle of the leg. This point does not change with time and so the 
% CoP components of this array can be defined here. 
% 
% Additionally, we can also set up the inequality constraints here as these
% are independent of time. 

exitflags = ones(timesteps,1)*10;
saved_results = zeros(timesteps,71);
saved_desired = zeros(timesteps,23);
saved_errors = zeros(timesteps,69);
saved_mse = zeros(timesteps,1);
apo_contact_forces = zeros(timesteps,12);

apo_contact_forces(1:end,5) = -link;
apo_contact_forces(1:end,11) = -link;

A_ineq = zeros(4,25);
b_ineq = zeros(4,1);

A_ineq(1,1) = 1;
A_ineq(2,1) = -1;
A_ineq(3,2) = 1;
A_ineq(4,2) = -1; 

b_ineq(1:4,1) = 30;

%% Begin time loop. 
% Loop over the number of frames for which data is available. This is
% hard-coded above based on the pre-calculated data, but again this
% should be implemented more abstractly later on. 

for i=1:timesteps
    
    %% Calculate time-dependent variables. 
    % Here the dynamic variables pertaining to the APO which are 
    % time-dependent are calculated. 
    %
    % First, the normalised spatial forces describing the force applied
    % by the APO are calculated. While in theory these are spatial, since 
    % the APO applies a force perpendicular to the thigh and no torques
    % they are actually 2D, but are represented as spatial vectors for
    % implementation purposes. These are 'normalised' in the sense that
    % this is the spatial force applied by the left/right APO link when the
    % left/right APO motor is operating with 1Nm of torque. 
    %
    % Next, we isolate the time-indexed 6x23 APO Jacobians corresponding 
    % to this time-step (from an array which contains all of the
    % Jacobians), and take the transpose.
    %
    % Finally, we form the normalised component of the APO generalised
    % forces by multiplying the normalised APO forces by the transpose of
    % the Jacobian. Again, this is 'normalised' in the sense that this 
    % generalised APO torque corresponds to a measured torque of 1 at the
    % APO. 
    
    left_apo_force = zeros(6,1);
    right_apo_force = zeros(6,1);
    
    left_apo_force(4,1) = cos(states(i,14));
    left_apo_force(5,1) = sin(states(i,14));
    right_apo_force(4,1) = cos(states(i,7));
    right_apo_force(5,1) = sin(states(i,7));
    right_apo_force = (1/link)*right_apo_force;
    left_apo_force = (1/link)*left_apo_force; 
    
    left_apo_transpose = left_jacobian(((i-1)*6+1):((i-1)*6+6), 1:end).';
    right_apo_transpose = right_jacobian(((i-1)*6+1):((i-1)*6+6), 1:end).';
    
    left_apo_normalised = left_apo_transpose*left_apo_force;
    right_apo_normalised = right_apo_transpose*right_apo_force; 
    
    %% Form linear system, and solve cascading QP.
    % Here we form the linear system for which a least squares based
    % solution is to be sought. The equations we aim to solve are the
    % following: 
    %
    % $$ {\bf A}{\bf \ddot{q}} + {\bf b} + {\bf g} = \tau_{grf} +
    % \tau_{APO} + \tau_{human}, $$
    %
    % $$ \tau_{APO} = \frac{A_{R}}{L}{\bf J^{T}_{L}}{\bf \hat{F}}^{L}_{applied} + \frac{A_{L}}{L}{\bf J^{T}_{R}}{\bf \hat{F}}^{R}_{applied}, $$
    %
    % $$ \tau_{human} = \tau_{desired}. $$
    %
    % The first equation above is the classical equation of motion.
    % Here, ${\bf A\ddot{q}}, {\bf b}$ and ${\bf g}$ are generalised forces
    % due to inertia, nonlinear effects and gravity, respectively. 
    % The vectors $\tau_{grf}$ and $\tau_{APO}$ are external forces due to 
    % ground reaction forces and the effect of the APO. The vector 
    % $\tau_{human}$ describes the generalised force due to the internal 
    % joint torques of the human. 
    %
    % The second equation describes that the generalised force due to the 
    % APO is caused by external forces at the left and right thigh. In 
    % this equation 6D normalised spatial force vectors (which are non-zero
    % in only the Fx and Fy directions, so are actually 2D) are scaled 
    % using the APO measured torques $A_{R}$ and $A_{L}$ and the link 
    % length $L$ and mapped from their point of application, namely the 
    % left and right thigh, on to generalised system forces via use of 
    % Jacobian mappings.
    %
    % Finally $\tau_{desired}$ is an input desired generalised force 
    % vector which we want the human torque contribution to be driven to. 
    %
    % Note that in matrix form they can be written as follows, after 
    % substituting equation 2 in to equation 1:
    %
    % $$ C{\bf x} = \left(\matrix{\frac{1}{L}J_{R}^{T}{\bf \hat{F}^{R}}_{applied}&\frac{1}{L}J_{L}^{T}{\bf \hat{F}^{L}}_{applied}&I_{23}\cr
    % O_{23,1}&O_{23,1}&I_{23}}\right)\left(\matrix{A_{R}\cr A_{L}\cr \tau_{human}}\right) $$
    %
    % $$ = \left(\matrix{{\bf A}{\bf \ddot{q}} + {\bf b} + {\bf g} - \tau_{grf}\cr \tau_{desired}}\right) = {\bf d}.$$
    %
    % Note that $C$ is a $46$ by $25$ matrix, ${\bf x}$ is a $25$ by $1$ 
    % column vector, and ${\bf b}$ is a $46$ by $1$ column vector. The 
    % first 23 elements of the vector d are equivalent to the net internal 
    % generalised forces calculated from getGeneralisedForces. The other 
    % half of d is chosen to achieve a certain behaviour of the human/APO 
    % system using the input desired torque. 
    %
    % The current implementation aims to achieve a percentage reduction in 
    % human joint torque at the left and right hip joints (flexion only).
    % This could be modified to aim for a percentage reduction over more 
    % joints. Indeed, this could be extended to requiring more effort at 
    % joints, or specifying that some joints receive more assistance 
    % than others. Finally, this vector could also be set to actual 
    % experimentally recorded joint torques in an attempt to drive the 
    % human torque contribution at one context towards another. 
    
    
    % Below we use a cascading QP to solve the problem. Note that the force
    % model has still not been fixed yet to account for pelvis rotation.
    % Let's see if this works...
    
    % FIRST QP LEVEL.
    
    H = 2*[zeros(46),zeros(46,23);zeros(23,46),eye(23)];
    f = [];
    A = [];
    b = [];
    
    C = zeros(23,69);
    C = [eye(23), eye(23), eye(23)];
    
    d = zeros(23,1);
    d(1:23,1) = net_internal(i,1:23);
    
    [x,fval,exitflag] = quadprog(H,f,A,b,C,d);
    
    % END FIRST QP LEVEL
    
    % SAVE FIRST SLACK VARIABLE.
    
    W_one = zeros(23,1)
    W_one(1:end,1) = x(47:end);
    
    % SECOND QP LEVEL. 
    
    H = 2*[zeros(48),zeros(48,23);zeros(23,48),eye(23)];
    % f,A,b unchanged
    
    C = zeros(46,71);
    C = [zeros(23,2), eye(23), eye(23), zeros(23); -[right_apo_normalised, left_apo_normalised], eye(23), zeros(23) -eye(23)];
    
    d = zeros(46,1);
    for loop=1:23
        d(loop,1) = net_internal(i,loop) - W_one(loop,1);
    end
    d(24:end,1) = zeros(23,1);
    
    [x, fval, exitflag] = quadprog(H,f,A,b,C,d);
    
    % END SECOND QP LEVEL.
    
    % SAVE SECOND SLACK VARIABLE.
    
    W_two = zeros(23,1);
    W_two(1:end,1) = x(49:end);
    
    % THIRD QP LEVEL.
    
    % H,f,A,b unchanged
    
    C = zeros(69,71);
    C = [zeros(23,2), eye(23), eye(23), zeros(23); -[right_apo_normalised, left_apo_normalised], eye(23), zeros(23), zeros(23);zeros(23,2), zeros(23), eye(23), -eye(23)];
    
    d = zeros(69,1);
    for loop=1:23
        d(loop,1) = net_internal(i,loop) - W_one(loop,1);
    end
    d(24:46,1) = W_two(1:23,1);
    d(47:end,1) = net_internal(i,1:23);
    d(53,1) = multiplier*net_internal(i,7);
    d(60,1) = multiplier*net_internal(i,14);
    
    [x, fval, exitflag] = quadprog(H,f,A,b,C,d);
    
    % END THIRD QP LEVEL
    
    % SAVE THIRD SLACK VARIABLE, JUST BECAUSE. 
    
    W_three = zeros(23,1);
    W_three(1:end,1) = x(49:end);
    
    % SAVE RESULTS
    
    exitflags(i,1) = exitflag;
    saved_results(i,1:end) = x;
    saved_errors(i,1:end) = C*x - d; 
    saved_mse(i,1) = mean(saved_errors(i,1:end).^2);
    
    %% Calculate required APO external forces. 
    % What the solution above gives us, alongside how well we are fitting
    % to the desired torque, the torque which should be applied to the 
    % APO motors. To analyse this output simulations will be run in 
    % OpenSim, explicitly providing these APO torques so as to calculate 
    % the resultant human torques as part of an OpenSim simulation. 
    % However, for simplicity the actual APO motors themselves aren't 
    % included in the OpenSim model. To represent the forces generated, 
    % the torques have to be mapped on to spatial forces which are applied
    % to the thighs of the user, which can then be unput as external forces
    % to OpenSim.  
    %
    % Earlier, the normalised spatial forces were calculated. We simply 
    % multiply these by our calculated APO motor torques to obtain the
    % corresponding spatial forces.
    %
    % Recalling that apo_contact_forces was initialised with 0's and the 
    % CoP parameters have already been set, it is only necessary to 
    % change the 4 elements of this array corresponding to the left &
    % right 2D external forces. 
    
    left_apo_force = x(2,1)*left_apo_force;
    right_apo_force = x(1,1)*right_apo_force;
    
    apo_contact_forces(i,1) = right_apo_force(4,1);
    apo_contact_forces(i,2) = right_apo_force(5,1);
    apo_contact_forces(i,7) = left_apo_force(4,1);
    apo_contact_forces(i,8) = left_apo_force(5,1);
    
%% End time loop.
% Loop over time-steps calculating and saving all necessary files as
% described above.

end

%% Save the overall results file. 

SAVE_FOLDER = [pathToData, '/multiplier=', num2str(multiplier)];
mkdir(SAVE_FOLDER)
save([SAVE_FOLDER, '/optimisation_results'], 'saved_results', 'multiplier', 'saved_desired', 'net_internal');

%% Save external force results to a file. 
% Write the APO output contacts to file. Themselves for now, but eventually
% this could just add them to the grf file somehow. 
%
% Write the output APO contact forces to file. The appropriate headings are
% put in place. For now, it is necessary to combine this file with an
% existing grf file before supplying the resulting file to OpenSim.
% However, in a later implementation this script will produce the full grf
% file itself, and potentially run it through OpenSim automatically.

EXT_FORCE_FILE = [SAVE_FOLDER, '/grf_apo.mot'];

labels = {'apo_force_vx', 'apo_force_vy', 'apo_force_vz',...
    'apo_force_px', 'apo_force_py', 'apo_force_pz', '1_apo_force_vx',...
    '1_apo_force_vy','1_apo_force_vz', '1_apo_force_px',... 
    '1_apo_force_py', '1_apo_force_pz'};

fid = fopen(EXT_FORCE_FILE, 'w');

%fprintf(fid, '%s\n', 'grf.mot');
%fprintf(fid, '%s\n', 'version=1');
%fprintf(fid, '%s\n', 'nRows=400');
%fprintf(fid, '%s\n', 'nColumns=19');
%fprintf(fid, '%s\n', 'inDegrees=yes');
%fprintf(fid, '%s\n', 'endheader');
for I = 1:size(labels,2),
    fprintf(fid,'%s\t', labels{I});
end
fprintf(fid, '\n');

dlmwrite(EXT_FORCE_FILE, apo_contact_forces, '-append', 'delimiter', '\t');
fclose(fid);

%% Notes and further work
% End of current iteration of script. Future improvements include:
%
% - Currently the desired human torque is limited to a percentage decrease 
%   in human joint effort over one or more joints, for one or more
%   percentages. Will include support for specifying a time-indexed torque
%   profile to act as a desired torque (allowing for analysis between
%   walking contexts on real experimental data).
%
% - Greater integration between C++ API script and Matlab (i.e. MEXing).
%
% - More automation, i.e. no reading in data, having to organise data 
%   manually following script completion, etc. 
%
% - No hard-coding; the time-step should be able to be calculated from the 
%   steps mentioned above. 
%
% - Ultimately want to take as input an OpenSim model file, experimental 
%   data (namely IK calculated from experimental marker data using OpenSim,
%   and experimentally obtained grf forces), and a desired human torque
%   contribution profile. Then, from entirely within this script (using
%   MEXing etc), produce an output APO torque profile to achieve said
%   desired human contribution. 
