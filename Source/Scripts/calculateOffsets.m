subjects = [1:4, 6:8];

x_offset = 0.2081*1000;
y_offset = -0.0953*1000;

for subject = subjects
    static = Data(['Static' num2str(subject) '.trc']);
    APO_x = static.getDataCorrespondingToLabel('V_SacralX') + x_offset;
    APO_y = static.getDataCorrespondingToLabel('V_SacralY') + y_offset;
    offsets.(['s' num2str(subject)]).offset_R_x = ...
        mean(APO_x - static.getDataCorrespondingToLabel('RHJCX'));
    offsets.(['s' num2str(subject)]).offset_R_y = ...
        mean(APO_y - static.getDataCorrespondingToLabel('RHJCY'));
    offsets.(['s' num2str(subject)]).offset_L_x = ...
        mean(APO_x - static.getDataCorrespondingToLabel('LHJCX'));
    offsets.(['s' num2str(subject)]).offset_L_y = ...
        mean(APO_y - static.getDataCorrespondingToLabel('LHJCY'));
end