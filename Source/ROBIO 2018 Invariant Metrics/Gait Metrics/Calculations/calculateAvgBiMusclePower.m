function result = calculateAvgBiMusclePower(...
    CMC, muscle, primary_joint, secondary_joints, weight)
% This function accepts a muscle name (string), a CMCResult, and a weight
% (e.g. the weight of the subject for which the CMC result was
% calculated). It calculates the average metabolic power of each muscle
% over the cycle, normalised by subject mass. This function assumes that
% the muscle crosses more than one joint, the names of which are stored in
% joints.

% Get the instantaneous muscle power over the cycle. 
power = CMC.metabolics.getDataCorrespondingToLabel(...
    ['metabolics_' muscle]);

% Get the instantaneous primary moment arm over the cycle.
primary_moment_arm = abs(...
    CMC.MomentArms.(primary_joint).getDataCorrespondingToLabel(muscle));

% Sum the instantaneous secondary moment arms over the cycle. 
temp = zeros(size(primary_moment_arm));
for i=1:length(secondary_joints)
    temp = temp + ...
        abs(CMC.MomentArms.(secondary_joints{i}). ...
        getDataCorrespondingToLabel(muscle));
end
secondary_moment_arm_sum = temp;

% Calculate the contribution of the muscle to the primary joint.
contribution = ...
    primary_moment_arm./(primary_moment_arm + secondary_moment_arm_sum);

% Calculate the muscle power accounting for moment arms.
adjusted_power = contribution.*power;

% Integrate and divide by weight and cycle length. 
time = CMC.metabolics.Timesteps;
result = trapz(time, adjusted_power)/(weight*(time(end)-time(1)));

end