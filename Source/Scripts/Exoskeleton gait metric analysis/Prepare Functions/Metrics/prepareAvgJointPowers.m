function result = prepareAvgJointPowers(...
    ~, ~, foot, context, assistance, result)
    %% Create structs for the joints of interest.
    
    % Hip adduction.
    Joints.hip_adduction_r.uniarticular = {'glut_med2_r', ...
        'glut_min2_r'};
    Joints.hip_adduction_r.biarticular.muscles{1} = 'glut_max1_r';
    Joints.hip_adduction_r.biarticular.joints{1} = ...
        {'hip_flexion_r', 'hip_rotation_r'};
    Joints.hip_adduction_r.biarticular.muscles{2} = 'glut_med3_r';
    Joints.hip_adduction_r.biarticular.joints{2} = ...
        {'hip_rotation_r', 'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{3} = 'glut_min1_r';
    Joints.hip_adduction_r.biarticular.joints{3} = ...
        {'hip_flexion_r', 'hip_rotation_r'};
    Joints.hip_adduction_r.biarticular.muscles{4} = 'glut_min3_r';
    Joints.hip_adduction_r.biarticular.joints{4} = ...
        {'hip_rotation_r', 'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{5} = 'peri_r';
    Joints.hip_adduction_r.biarticular.joints{5} = ...
        {'hip_rotation_r'};
    Joints.hip_adduction_r.biarticular.muscles{6} = 'sar_r';
    Joints.hip_adduction_r.biarticular.joints{6} = ...
        {'knee_angle_r'};
    Joints.hip_adduction_r.biarticular.muscles{7} = 'tfl_r';
    Joints.hip_adduction_r.biarticular.joints{7} = ...
        {'hip_flexion_r', 'hip_rotation_r'};
    Joints.hip_adduction_r.biarticular.muscles{8} = 'add_brev_r';
    Joints.hip_adduction_r.biarticular.joints{8} = ...
        {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{9} = 'add_long_r';
    Joints.hip_adduction_r.biarticular.joints{9} = ...
        {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{10} = 'add_mag1_r';
    Joints.hip_adduction_r.biarticular.joints{10} = ...
        {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{11} = 'add_mag2_r';
    Joints.hip_adduction_r.biarticular.joints{11} = ...
        {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{12} = 'add_mag3_r';
    Joints.hip_adduction_r.biarticular.joints{12} = ...
        {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{13} = 'bifemlh_r';
    Joints.hip_adduction_r.biarticular.joints{13} = ...
        {'hip_flexion_r', 'knee_angle_r'};
    Joints.hip_adduction_r.biarticular.muscles{14} = 'grac_r';
    Joints.hip_adduction_r.biarticular.joints{14} = ...
        {'hip_flexion_r', 'knee_angle_r'};
    Joints.hip_adduction_r.biarticular.muscles{15} = 'pect_r';
    Joints.hip_adduction_r.biarticular.joints{15} = ...
        {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{16} = 'semimem_r';
    Joints.hip_adduction_r.biarticular.joints{16} = ...
        {'hip_flexion_r', 'knee_angle_r'};
    Joints.hip_adduction_r.biarticular.muscles{17} = 'semiten_r';
    Joints.hip_adduction_r.biarticular.joints{17} = ...
        {'hip_flexion_r', 'knee_angle_r'};
    
    % Hip flexion.
    Joints.hip_flexion_r.uniarticular = {'glut_max2_r', 'glut_max3_r'};
    Joints.hip_flexion_r.biarticular.muscles{1} = 'add_brev_r';
    Joints.hip_flexion_r.biarticular.joints{1} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{2} = 'add_long_r';
    Joints.hip_flexion_r.biarticular.joints{2} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{3} = 'glut_med1_r';
    Joints.hip_flexion_r.biarticular.joints{3} = ...
        {'hip_adduction_r', 'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{4} = 'glut_min1_r';
    Joints.hip_flexion_r.biarticular.joints{4} = ...
        {'hip_adduction_r', 'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{5} = 'grac_r';
    Joints.hip_flexion_r.biarticular.joints{5} = ...
        {'hip_adduction_r', 'knee_angle_r'};
    Joints.hip_flexion_r.biarticular.muscles{6} = 'iliacus_r';
    Joints.hip_flexion_r.biarticular.joints{6} = {'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{7} = 'pect_r';
    Joints.hip_flexion_r.biarticular.joints{7} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{8} = 'psoas_r';
    Joints.hip_flexion_r.biarticular.joints{8} = {'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{9} = 'rect_fem_r';
    Joints.hip_flexion_r.biarticular.joints{9} = {'knee_angle_r'};
    Joints.hip_flexion_r.biarticular.muscles{10} = 'sar_r';
    Joints.hip_flexion_r.biarticular.joints{10} = ...
        {'knee_angle_r', 'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{11} = 'tfl_r';
    Joints.hip_flexion_r.biarticular.joints{11} = ...
        {'hip_rotation_r', 'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{12} = 'add_mag1_r';
    Joints.hip_flexion_r.biarticular.joints{12} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{13} = 'add_mag2_r';
    Joints.hip_flexion_r.biarticular.joints{13} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{14} = 'add_mag3_r';
    Joints.hip_flexion_r.biarticular.joints{14} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{15} = 'bifemlh_r';
    Joints.hip_flexion_r.biarticular.joints{15} = ...
        {'hip_adduction_r', 'knee_angle_r'};
    Joints.hip_flexion_r.biarticular.muscles{16} = 'glut_max1_r';
    Joints.hip_flexion_r.biarticular.joints{16} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{17} = 'glut_med3_r';
    Joints.hip_flexion_r.biarticular.joints{17} = ...
        {'hip_adduction_r', 'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{18} = 'glut_min3_r';
    Joints.hip_flexion_r.biarticular.joints{18} = ...
        {'hip_adduction_r', 'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{19} = 'semimem_r';
    Joints.hip_flexion_r.biarticular.joints{19} = ...
        {'hip_adduction_r', 'knee_angle_r'};
    Joints.hip_flexion_r.biarticular.muscles{20} = 'semiten_r';
    Joints.hip_flexion_r.biarticular.joints{20} = ...
        {'hip_adduction_r', 'knee_angle_r'};
    
    % Knee. 
    Joints.knee_angle_r.uniarticular = ...
        {'bifemsh_r', 'vas_int_r', 'vas_lat_r', 'vas_med_r'};
    Joints.knee_angle_r.biarticular.muscles{1} = 'bifemlh_r';
    Joints.knee_angle_r.biarticular.joints{1} = ...
        {'hip_adduction_r', 'hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{2} = 'grac_r';
    Joints.knee_angle_r.biarticular.joints{2} = ...
        {'hip_adduction_r', 'hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{3} = 'lat_gas_r';
    Joints.knee_angle_r.biarticular.joints{3} = ...
        {'ankle_angle_r', 'subtalar_angle_r'};
    Joints.knee_angle_r.biarticular.muscles{4} = 'med_gas_r';
    Joints.knee_angle_r.biarticular.joints{4} = ...
        {'ankle_angle_r', 'subtalar_angle_r'};
    Joints.knee_angle_r.biarticular.muscles{5} = 'sar_r';
    Joints.knee_angle_r.biarticular.joints{5} = ...
        {'hip_adduction_r', 'hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{6} = 'semimem_r';
    Joints.knee_angle_r.biarticular.joints{6} = ...
        {'hip_adduction_r', 'hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{7} = 'semiten_r';
    Joints.knee_angle_r.biarticular.joints{7} = ...
        {'hip_adduction_r', 'hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{8} = 'rect_fem_r';
    Joints.knee_angle_r.biarticular.joints{8} = {'hip_flexion_r'};
    
    % Ankle. 
    Joints.ankle_angle_r.uniarticular = {};
    Joints.ankle_angle_r.biarticular.muscles{1} = 'flex_dig_r';
    Joints.ankle_angle_r.biarticular.joints{1} = ...
        {'subtalar_angle_r', 'mtp_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{2} = 'flex_hal_r';
    Joints.ankle_angle_r.biarticular.joints{2} = ...
        {'subtalar_angle_r', 'mtp_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{3} = 'lat_gas_r';
    Joints.ankle_angle_r.biarticular.joints{3} = ...
        {'knee_angle_r', 'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{4} = 'med_gas_r';
    Joints.ankle_angle_r.biarticular.joints{4} = ...
        {'knee_angle_r', 'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{5} = 'per_brev_r';
    Joints.ankle_angle_r.biarticular.joints{5} = ...
        {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{6} = 'per_long_r';
    Joints.ankle_angle_r.biarticular.joints{6} = ...
        {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{7} = 'soleus_r';
    Joints.ankle_angle_r.biarticular.joints{7} = ...
        {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{8} = 'tib_post_r';
    Joints.ankle_angle_r.biarticular.joints{8} = ...
        {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{9} = 'ext_hal_r';
    Joints.ankle_angle_r.biarticular.joints{9} = ...
        {'subtalar_angle_r', 'mtp_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{10} = 'tib_ant_r';
    Joints.ankle_angle_r.biarticular.joints{10} = ...
        {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{11} = 'ext_dig_r';
    Joints.ankle_angle_r.biarticular.joints{11} = ...
        {'subtalar_angle_r', 'mtp_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{12} = 'per_tert_r';
    Joints.ankle_angle_r.biarticular.joints{12} = ...
        {'subtalar_angle_r'};
    
    % Mirror to the left handside.
    joint_names = fieldnames(Joints);
    n_joints = length(joint_names);
    for i=1:n_joints
        left_joint = [joint_names{i}(1:end-1) 'l'];
        n_uniarticular = length(Joints.(joint_names{i}).uniarticular);
        Joints.(left_joint).uniarticular = cell(1, n_uniarticular);
        for j=1:n_uniarticular
            Joints.(left_joint).uniarticular{j} = ...
                [Joints.(joint_names{i}).uniarticular{j}(1:end-1) 'l'];
        end
        n_biarticular = ...
            length(Joints.(joint_names{i}).biarticular.muscles);
        Joints.(left_joint).biarticular.muscles = cell(1, n_biarticular);
        Joints.(left_joint).biarticular.joints = cell(1, n_biarticular);
        for j=1:n_biarticular
            Joints.(left_joint).biarticular.muscles{j} = ...
                [Joints.(joint_names{i}).biarticular. ...
                muscles{j}(1:end-1) 'l'];
            n_other_joints = ...
                length(Joints.(joint_names{i}).biarticular.joints{j});
            Joints.(left_joint).biarticular.joints{j} = ...
                cell(1, n_other_joints);
            for k=1:n_other_joints
                Joints.(left_joint).biarticular.joints{j}{k} = ...
                    [Joints.(joint_names{i}).biarticular. ...
                    joints{j}{k}(1:end-1) 'l'];
            end
        end
    end
    
    % Back. 
    Joints.lumbar_extension.uniarticular = {};
    Joints.lumbar_extension.biarticular.muscles{1} = 'ercspn_l';
    Joints.lumbar_extension.biarticular.joints{1} = ...
        {'lumbar_bending', 'lumbar_rotation'};
    Joints.lumbar_extension.biarticular.muscles{2} = 'ercspn_r';
    Joints.lumbar_extension.biarticular.joints{2} = ...
        {'lumbar_bending', 'lumbar_rotation'};
    Joints.lumbar_extension.biarticular.muscles{3} = 'extobl_l';
    Joints.lumbar_extension.biarticular.joints{3} = ...
        {'lumbar_bending', 'lumbar_rotation'};
    Joints.lumbar_extension.biarticular.muscles{4} = 'extobl_r';
    Joints.lumbar_extension.biarticular.joints{4} = ...
        {'lumbar_bending', 'lumbar_rotation'};
    Joints.lumbar_extension.biarticular.muscles{5} = 'intobl_l';
    Joints.lumbar_extension.biarticular.joints{5} = ...
        {'lumbar_bending', 'lumbar_rotation'};
    Joints.lumbar_extension.biarticular.muscles{6} = 'intobl_r';
    Joints.lumbar_extension.biarticular.joints{6} = ...
        {'lumbar_bending', 'lumbar_rotation'};
    
    %% Pass off to calculateAvgGroupPowers. 

    % Gain access to the appropriate data.
    cmc = result.CMC{foot, context, assistance};
    weight = result.Properties.Weight;

    % Create cell array to hold temporary results, and a temporary variable
    % to store the total average metabolic power.
    n_cmcs = vectorSize(cmc);
    temp{n_joints, n_cmcs} = {};
    
    % Redefine after adding left joints and back joint.
    joint_names = fieldnames(Joints);
    n_joints = length(joint_names);

    for i=1:n_joints
        % Calculate the metrics and store the results. 
        for j=1:n_cmcs
            temp{i,j} = calculateAvgJointPower(cmc{j}, joint_names{i}, ...
                Joints.(joint_names{i}), weight);
        end

        % Store results properly and clear temp variable. 
        result.MetricsData.AvgJointPowers.(joint_names{i}){ ...
            foot, context, assistance} = temp(i,:);
    end
    
    % Clear temp variable. 
    clear('temp');

end

