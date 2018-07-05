function offsets = calculateOffsets()

subjects = [1:4, 6:8];

x_offset = 0.2081*1000;
y_offset = -0.0953*1000;

current_dir = pwd;
cd([getenv('EXOPT_HOME') filesep 'Source\Scripts']);

for subject = subjects
    static = Data(['Static' num2str(subject) '.trc']);
    APO_x = static.getDataCorrespondingToLabel('V_SacralX') + x_offset;
    APO_y = static.getDataCorrespondingToLabel('V_SacralY') + y_offset;
    
    % Re-convert to meters when calculating offsets.
    offsets.(['s' num2str(subject)]).R_x = ...
        mean(APO_x - static.getDataCorrespondingToLabel('RHJCX'))/1000;
    offsets.(['s' num2str(subject)]).R_y = ...
        mean(APO_y - static.getDataCorrespondingToLabel('RHJCY'))/1000;
    offsets.(['s' num2str(subject)]).L_x = ...
        mean(APO_x - static.getDataCorrespondingToLabel('LHJCX'))/1000;
    offsets.(['s' num2str(subject)]).L_y = ...
        mean(APO_y - static.getDataCorrespondingToLabel('LHJCY'))/1000;
end

cd(current_dir);

end