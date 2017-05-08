test = OpenSimTrial('testing_adjusted.osim','ik0.mot','normal','grf0.mot','test')
id = test.runID(0.5,1.0)
joints = cell(0);
joints{1} = 'hip_flexion_r';
multiplier = 0.5
des = Desired('percentage_reduction',joints,multiplier)
des = des.evaluateDesired(id)
plot(des.Result.getDataCorrespondingToLabel('hip_flexion_r_moment'))
hold on
plot(des.IDResult.id.getDataCorrespondingToLabel('hip_flexion_r_moment'))
