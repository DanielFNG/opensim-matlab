function [CoPML] = getCopML( GRF , foot)
%GETHIPROM Summary of this function goes here
%   Detailed explanation goes here

cop_data = GRF.getDataCorrespondingToLabel(['    ground_force' num2str(foot) '_pz']);

Stance = find(cop_data(1:end)~=0);

max_pk = max(cop_data(Stance(1):Stance(end)));

min_pk = min(cop_data(Stance(1):Stance(end)));

CoPML= max_pk - min_pk;
  
        
        



        

