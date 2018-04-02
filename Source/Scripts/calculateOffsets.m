subjects = [1:4, 6:8];

for subject = subjects
    static = Data(['Static' num2str(subject) '.trc']);
    APO_x = static.getDataCorrespondingToLabel('V_SacralX') + 0.2081;
    APO_y = static.getDataCorrespondingToLabel('V_SacralY') - 0.0953;
    offset_R_x = APO_x - static.getDataCorrespondingToLabel('RHJCX');
    offset_R_y = APO_y - static.getDataCorrespondingToLabel('RHJCY');
    offset_L_x = APO_x - static.getDataCorrespondingToLabel('LHJCX');
    offset_L_y = APO_y - static.getDataCorrespondingToLabel('LHJCY');
end