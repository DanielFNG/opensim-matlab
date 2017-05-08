input = OpenSimTrial('testing_adjusted.osim','ik0.mot','normal','grf0.mot','test_matchid');
tomatch = OpenSimTrial('testing_adjusted.osim','ik1.mot','normal','grf1.mot','test_matchid');
id_input = input.runID(0.0,4.0);
id_des = tomatch.runID(0.0,4.0);
joints = 'all';
shift = 'hip_flexion_r';
des = Desired('match_id',joints,id_des,shift);
des = des.evaluateDesired(id_input);

% Plot some graphs.
% Hip flexion r.
figure;
plot(des.Result.getDataCorrespondingToLabel('hip_flexion_r_moment'))
hold on
plot(des.IDResult.id.getDataCorrespondingToLabel('hip_flexion_r_moment'))
title('hip flexion r')

% Hip flexion l.
figure;
plot(des.Result.getDataCorrespondingToLabel('hip_flexion_l_moment'))
hold on
plot(des.IDResult.id.getDataCorrespondingToLabel('hip_flexion_l_moment'))
title('hip flexion l')

% Knee angle r. 
figure
plot(des.Result.getDataCorrespondingToLabel('knee_angle_r_moment'))
hold on
plot(des.IDResult.id.getDataCorrespondingToLabel('knee_angle_r_moment'))
title('knee angle r')
