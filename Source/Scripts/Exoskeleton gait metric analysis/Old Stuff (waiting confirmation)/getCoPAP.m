function [CoPAP] = getCopAP( GRF , foot)
%GETHIPROM Summary of this function goes here
%   Detailed explanation goes here

cop_data = GRF.getDataCorrespondingToLabel(['    ground_force' num2str(foot) '_px']);

Ten = round(length(cop_data)/10);
Swing_start = find(cop_data(6:end)==0);

if isempty(Swing_start)
    Swing_start = 60;
end

[max_pk,~] = findpeaks(cop_data(1:Ten));

[min_pk,~] = findpeaks(cop_data((Swing_start(1)-Ten):end)*-1);

isempty(max_pk);

if isempty(max_pk) == 1
    max_pk = max(cop_data);
end

if isempty(min_pk) == 1
    min_pk = min(cop_data);
end

CoPAP= max_pk(end) + min_pk(1);
  
        
        



        

