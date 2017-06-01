% Some parameters.
start_time = 0.0;
end_time = 4.0;
load_type = 'normal';
trial_directory = 'ost';
model_directory = 'efm';
force_model = 'linear';

% Construct OpenSimTrial.
trial = OpenSimTrial('testing_adjusted.osim', 'ik0.mot', 'grf0.mot', trial_directory);

% Run RRA.
rra = trial.runRRA(load_type, start_time, end_time); 

% Construct Exoskeleton.
apo = Exoskeleton('APO');

% Get Exoskeleton to construct LinearForceModel.
model = apo.constructExoskeletonForceModel(rra.states, model_directory, force_model);

% Construct some nominal trajectories for the APO motor torques. Out of
% phase sin-waves of amplitude 15. 
x = 0:2*pi/999:2*pi;
y = 15*sin(x);
z = 15*sin(x+pi);
t = zeros(2,size(x,2));
t(1,1:end) = y;
t(2,1:end) = z;

% Calculate the spatial forces resulting from these trajectories. 
spatial = model.calculateSpatialForcesFromTorqueTrajectory(t.');

% Save the Fx,Fy values for each contact point.
forces = zeros(8,size(spatial.ForceSet,1));
for j=1:size(spatial.ForceSet,1)
    forces(1,j) = spatial.ForceSet{j, 1}(4); % right_link_fx
    forces(2,j) = spatial.ForceSet{j, 1}(5); % right_link_fy
    
    forces(3,j) = spatial.ForceSet{j, 2}(4); % left_link_fx
    forces(4,j) = spatial.ForceSet{j, 2}(5); % left_link_fy
    
    forces(5,j) = spatial.ForceSet{j, 3}(4); % right_group_fx
    forces(6,j) = spatial.ForceSet{j, 3}(5); % right_group_fy
    
    forces(7,j) = spatial.ForceSet{j, 4}(4); % left_group_fx
    forces(8,j) = spatial.ForceSet{j, 4}(5); % left_group_fy
end

% Plot some graphs from this.
titles = {'Right link', '', 'Left link', '', 'Right group', '', 'Left group'};
labels = {'right', 'left', 'fx', 'fy'};

figure;
plot(t(1,1:end));
hold on;
plot(t(2,1:end)); % Motor torque profiles
title('APO Motor Torques');
legend(labels(1:2));

for i=1:2:7
    figure;
    plot(forces(i,1:end));
    hold on;
    plot(forces(i+1,1:end)); % Force at each contact point.
    title(titles(i));
    legend(labels(3:4));
end

% For now the results from this look reasonable. Distance to link about
% 0.25, so should be roughly sin looking between -60, 60 (4*15) which it
% is. Same for the groups but with different numbers. Later I can implement a
% unit test for this when I compare by getting the hip flexion states and 
% computing what the forces should be using this (i.e. the appropriate
% calculations). The fact that the group forces look as I expect means 
% there probably isn't a mistake in the Jacobian calculations. So, happy
% with this testing for now. 

