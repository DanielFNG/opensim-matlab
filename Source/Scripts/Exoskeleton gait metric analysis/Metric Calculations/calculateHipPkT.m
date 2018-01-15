function result = calculateHipPkT(ID, weight, label)
% Calculate the weight normalised difference in peak to peak torque at a 
% co-ordinate defined by some label. Input is an Inverse Dynamics Data 
% object. 

trajectory = ID.getDataCorrespondingToLabel(label);
result = (max(trajectory) - min(trajectory))/weight;