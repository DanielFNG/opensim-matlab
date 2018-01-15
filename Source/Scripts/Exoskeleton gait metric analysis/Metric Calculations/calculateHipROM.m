function result = calculateHipROM(IK, label)
% Calculate difference in peak to peak angle co-ordinate defined by some 
% label. Input is an IK Data object. 

trajectory = IK.getDataCorrespondingToLabel(label);
result = max(trajectory) - min(trajectory);