subjects = [1:4, 6:8];

x_offset = 0.2081*1000;
y_offset = -0.0953*1000;

for subject = subjects
    static = Data(['Static' num2str(subject) '.trc']);
    APO_x = static.getDataCorrespondingToLabel('V_SacralX') + x_offset;
    APO_y = static.getDataCorrespondingToLabel('V_SacralY') + y_offset;
    offset_R_x = abs(APO_x - static.getDataCorrespondingToLabel('RHJCX'));
    offset_R_y = abs(APO_y - static.getDataCorrespondingToLabel('RHJCY'));
    offset_L_x = abs(APO_x - static.getDataCorrespondingToLabel('LHJCX'));
    offset_L_y = abs(APO_y - static.getDataCorrespondingToLabel('LHJCY'));
end