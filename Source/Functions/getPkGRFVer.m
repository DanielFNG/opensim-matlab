function [ Pk_GRF ] = getPkGRFVer( GRF , foot, Subject, Subject_weight, peak)
%GETHIPROM Summary of this function goes here
%   Detailed explanation goes here

grf_data = GRF.getDataCorrespondingToLabel(['    ground_force' num2str(foot) '_vy']);
Mid_stance = round(length(grf_data)*0.3);
if peak == 1
    Pk_GRF = (max(grf_data(1:Mid_stance)))/Subject_weight(Subject);
else
    Pk_GRF = (max(grf_data(Mid_stance:end)))/Subject_weight(Subject);
end    
        
        



        

