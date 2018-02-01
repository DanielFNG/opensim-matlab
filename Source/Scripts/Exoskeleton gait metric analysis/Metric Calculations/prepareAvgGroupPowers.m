function result = prepareAvgGroupPowers(foot, context, assistance, result)

    % Create structs for the joints of interest. 
    Joints.hip_adduction_r.uniarticular = {'glut_med2_r', ...
        'glut_min2_r'};
    Joints.hip_adduction_r.biarticular.muscles{1} = 'glut_max1_r';
    Joints.hip_adduction_r.biarticular.joints{1} = {'hip_flexion_r', 'hip_rotation_r'};
    Joints.hip_adduction_r.biarticular.muscles{2} = 'glut_med3_r';
    Joints.hip_adduction_r.biarticular.joints{2} = {'hip_rotation_r', 'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{3} = 'glut_min1_r';
    Joints.hip_adduction_r.biarticular.joints{3} = {'hip_flexion_r', 'hip_rotation_r'};
    Joints.hip_adduction_r.biarticular.muscles{4} = 'glut_min3_r';
    Joints.hip_adduction_r.biarticular.joints{4} = {'hip_rotation_r', 'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{5} = 'peri_r';
    Joints.hip_adduction_r.biarticular.joints{5} = {'hip_rotation_r'};
    Joints.hip_adduction_r.biarticular.muscles{6} = 'sar_r';
    Joints.hip_adduction_r.biarticular.joints{6} = {'knee_angle_r'};
    Joints.hip_adduction_r.biarticular.muscles{7} = 'tfl_r';
    Joints.hip_adduction_r.biarticular.joints{7} = {'hip_flexion_r', 'hip_rotation_r'};
    Joints.hip_adduction_r.biarticular.muscles{8} = 'add_brev_r';
    Joints.hip_adduction_r.biarticular.joints{8} = {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{9} = 'add_long_r';
    Joints.hip_adduction_r.biarticular.joints{9} = {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{10} = 'add_mag1_r';
    Joints.hip_adduction_r.biarticular.joints{10} = {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{11} = 'add_mag2_r';
    Joints.hip_adduction_r.biarticular.joints{11} = {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{12} = 'add_mag3_r';
    Joints.hip_adduction_r.biarticular.joints{12} = {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{13} = 'bifemlh_r';
    Joints.hip_adduction_r.biarticular.joints{13} = {'hip_flexion_r', 'knee_angle_r'};
    Joints.hip_adduction_r.biarticular.muscles{14} = 'grac_r';
    Joints.hip_adduction_r.biarticular.joints{14} = {'hip_flexion_r', 'knee_angle_r'};
    Joints.hip_adduction_r.biarticular.muscles{15} = 'pect_r';
    Joints.hip_adduction_r.biarticular.joints{15} = {'hip_flexion_r'};
    Joints.hip_adduction_r.biarticular.muscles{16} = 'semimem_r';
    Joints.hip_adduction_r.biarticular.joints{16} = {'hip_flexion_r', 'knee_angle_r'};
    Joints.hip_adduction_r.biarticular.muscles{17} = 'semiten_r';
    Joints.hip_adduction_r.biarticular.joints{17} = {'hip_flexion_r', 'knee_angle_r'};
    
    Joints.hip_flexion_r.uniarticular = {'glut_max2_r', 'glut_max3_r'};
    Joints.hip_flexion_r.biarticular.muscles{1} = 'add_brev_r';
    Joints.hip_flexion_r.biarticular.joints{1} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{2} = 'add_long_r';
    Joints.hip_flexion_r.biarticular.joints{2} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{3} = 'glut_med1_r';
    Joints.hip_flexion_r.biarticular.joints{3} = {'hip_adduction_r', 'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{4} = 'glut_min1_r';
    Joints.hip_flexion_r.biarticular.joints{4} = {'hip_adduction_r', 'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{5} = 'grac_r';
    Joints.hip_flexion_r.biarticular.joints{5} = {'hip_adduction_r', 'knee_angle_r'};
    Joints.hip_flexion_r.biarticular.muscles{6} = 'iliacus_r';
    Joints.hip_flexion_r.biarticular.joints{6} = {'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{7} = 'pect_r';
    Joints.hip_flexion_r.biarticular.joints{7} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{8} = 'psoas_r';
    Joints.hip_flexion_r.biarticular.joints{8} = {'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{9} = 'rect_fem_r';
    Joints.hip_flexion_r.biarticular.joints{9} = {'knee_angle_r'};
    Joints.hip_flexion_r.biarticular.muscles{10} = 'sar_r';
    Joints.hip_flexion_r.biarticular.joints{10} = {'knee_angle_r', 'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{11} = 'tfl_r';
    Joints.hip_flexion_r.biarticular.joints{11} = {'hip_rotation_r', 'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{12} = 'add_mag1_r';
    Joints.hip_flexion_r.biarticular.joints{12} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{13} = 'add_mag2_r';
    Joints.hip_flexion_r.biarticular.joints{13} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{14} = 'add_mag3_r';
    Joints.hip_flexion_r.biarticular.joints{14} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{15} = 'bifemlh_r';
    Joints.hip_flexion_r.biarticular.joints{15} = {'hip_adduction_r', 'knee_angle_r'};
    Joints.hip_flexion_r.biarticular.muscles{16} = 'glut_max1_r';
    Joints.hip_flexion_r.biarticular.joints{16} = {'hip_adduction_r'};
    Joints.hip_flexion_r.biarticular.muscles{17} = 'glut_med3_r';
    Joints.hip_flexion_r.biarticular.joints{17} = {'hip_adduction_r', 'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{18} = 'glut_min3_r';
    Joints.hip_flexion_r.biarticular.joints{18} = {'hip_adduction_r', 'hip_rotation_r'};
    Joints.hip_flexion_r.biarticular.muscles{19} = 'semimem_r';
    Joints.hip_flexion_r.biarticular.joints{19} = {'hip_adduction_r', 'knee_angle_r'};
    Joints.hip_flexion_r.biarticular.muscles{20} = 'semiten_r';
    Joints.hip_flexion_r.biarticular.joints{20} = {'hip_adduction_r', 'knee_angle_r'};
    
    Joints.knee_angle_r.uniarticular = {'bifemsh_r', 'vas_int_r', 'vas_lat_r', 'vas_med_r'};
    Joints.knee_angle_r.biarticular.muscles{1} = 'bifemlh_r';
    Joints.knee_angle_r.biarticular.joints{1} = {'hip_adduction_r, hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{2} = 'grac_r';
    Joints.knee_angle_r.biarticular.joints{2} = {'hip_adduction_r, hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{3} = 'lat_gas_r';
    Joints.knee_angle_r.biarticular.joints{3} = {'ankle_angle_r', 'subtalar_angle_r'};
    Joints.knee_angle_r.biarticular.muscles{4} = 'med_gas_r';
    Joints.knee_angle_r.biarticular.joints{4} = {'ankle_angle_r', 'subtalar_angle_r'};
    Joints.knee_angle_r.biarticular.muscles{5} = 'sar_r';
    Joints.knee_angle_r.biarticular.joints{5} = {'hip_adduction_r', 'hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{6} = 'semimem_r';
    Joints.knee_angle_r.biarticular.joints{6} = {'hip_adduction_r', 'hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{7} = 'semiten_r';
    Joints.knee_angle_r.biarticular.joints{7} = {'hip_adduction_r', 'hip_flexion_r'};
    Joints.knee_angle_r.biarticular.muscles{8} = 'rect_fem_r';
    Joints.knee_angle_r.biarticular.joints{8} = {'hip_flexion_r'};
    
    Joints.ankle_angle_r.uniarticular = {};
    Joints.ankle_angle_r.biarticular.muscles{1} = 'flex_dig_r';
    Joints.ankle_angle_r.biarticular.joints{1} = {'subtalar_angle_r', 'mtp_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{2} = 'flex_hal_r';
    Joints.ankle_angle_r.biarticular.joints{2} = {'subtalar_angle_r', 'mtp_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{3} = 'lat_gas_r';
    Joints.ankle_angle_r.biarticular.joints{3} = {'knee_angle_r', 'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{4} = 'med_gas_r';
    Joints.ankle_angle_r.biarticular.joints{4} = {'knee_angle_r', 'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{5} = 'per_brev_r';
    Joints.ankle_angle_r.biarticular.joints{5} = {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{6} = 'per_long_r';
    Joints.ankle_angle_r.biarticular.joints{6} = {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{7} = 'soleus_r';
    Joints.ankle_angle_r.biarticular.joints{7} = {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{8} = 'tib_post_r';
    Joints.ankle_angle_r.biarticular.joints{8} = {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{9} = 'ext_hal_r';
    Joints.ankle_angle_r.biarticular.joints{9} = {'subtalar_angle_r', 'mtp_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{10} = 'tib_ant_r';
    Joints.ankle_angle_r.biarticular.joints{10} = {'subtalar_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{11} = 'ext_dig_r';
    Joints.ankle_angle_r.biarticular.joints{11} = {'subtalar_angle_r', 'mtp_angle_r'};
    Joints.ankle_angle_r.biarticular.muscles{12} = 'per_tert_r';
    Joints.ankle_angle_r.biarticular.joints{12} = {'subtalar_angle_r'};
    
    Joints.lumbar_extension.uniarticular = {};
    Joints.ankle_angle_r.biarticular.muscles{1} = 'ercspn_l';
    Joints.ankle_angle_r.biarticular.joints{1} = {'lumbar_bending', 'lumbar_rotation'};
    Joints.ankle_angle_r.biarticular.muscles{2} = 'ercspn_r';
    Joints.ankle_angle_r.biarticular.joints{2} = {'lumbar_bending', 'lumbar_rotation'};
    Joints.ankle_angle_r.biarticular.muscles{3} = 'extobl_l';
    Joints.ankle_angle_r.biarticular.joints{3} = {'lumbar_bending', 'lumbar_rotation'};
    Joints.ankle_angle_r.biarticular.muscles{4} = 'extobl_r';
    Joints.ankle_angle_r.biarticular.joints{4} = {'lumbar_bending', 'lumbar_rotation'};
    Joints.ankle_angle_r.biarticular.muscles{5} = 'intobl_l';
    Joints.ankle_angle_r.biarticular.joints{5} = {'lumbar_bending', 'lumbar_rotation'};
    Joints.ankle_angle_r.biarticular.muscles{6} = 'intobl_r';
    Joints.ankle_angle_r.biarticular.joints{6} = {'lumbar_bending', 'lumbar_rotation'};




    % Define appropriate labels for each lower body muscle group. 
    MuscleGroups.hip_abd = strsplit(['glut_max1_r glut_med1_r ' ...
        'glut_med2_r glut_med3_r glut_min1_r glut_min2_r glut_min3_r ' ...
        'peri_r sar_r tfl_r']);
    MuscleGroups.hip_flex = strsplit(['add_brev_r add_long_r ' ...
        'glut_med1_r glut_min1_r grac_r iliacus_r pect_r psoas_r ' ...
        'rect_fem_r sar_r tfl_r']);
    MuscleGroups.hip_inrot = strsplit(['glut_med1_r glut_min1_r ' ...
        'iliacus_r psoas_r tfl_r']);
    MuscleGroups.hip_exrot = strsplit(['gem_r glut_med3_r glut_min3_r ' ...
        'peri_r quad_fem_r']);
    MuscleGroups.hip_ext = strsplit(['add_long_r add_mag1_r add_mag2_r' ...
        ' add_mag3_r bifemlh_r glut_max1_r glut_max2_r glut_max3_r ' ...
        'glut_med3_r glut_min3_r semimem_r semiten_r']);
    MuscleGroups.hip_add = strsplit(['add_brev_r add_long_r add_mag1_r' ...
        ' add_mag2_r add_mag3_r bifemlh_r grac_r pect_r semimem_r ' ...
        'semiten_r']);
    MuscleGroups.knee_bend = strsplit(['bifemlh_r bifemsh_r grac_r ' ...
        'lat_gas_r med_gas_r sar_r semimem_r semiten_r']);
    MuscleGroups.knee_ext = strsplit(['rect_fem_r vas_int_r vas_lat_r ' ...
        'vas_med_r']);
    MuscleGroups.ankle_pf = strsplit(['flex_dig_r flex_hal_r lat_gas_r' ...
        ' med_gas_r per_brev_r per_long_r soleus_r tib_post_r']);
    MuscleGroups.inverter = strsplit(['ext_hal_r flex_dig_r flex_hal_r' ...
        ' tib_ant_r tib_post_r']);
    MuscleGroups.ankle_df = strsplit(['ext_dig_r ext_hal_r per_tert_r ' ...
        'tib_ant_r']);
    MuscleGroups.everter = strsplit(['ext_dig_r per_brev_r per_long_r ' ...
        'per_tert_r']);

    muscle_group_names = fieldnames(MuscleGroups);
    n_groups = length(muscle_group_names);

    % If necessary replace the 'r' suffix with 'l' if we are in the left
    % foot case. 
    if foot == 2
        for i=1:n_groups
            for j=1:length(MuscleGroups.(muscle_group_names{i}))
                MuscleGroups.(muscle_group_names{i}){j} = [MuscleGroups.(muscle_group_names{i}){j}(1:end-1) 'l'];
            end
        end
    end

    % Define appropriate labels for the back muscles.
    MuscleGroups.back_ext = strsplit('ercspn_l ercspn_r');
    MuscleGroups.back_rlb = strsplit('ercspn_r extobl_r intobl_r');
    MuscleGroups.back_introt = strsplit('ercspn_r extobl_l intobl_r');
    MuscleGroups.back_llb = strsplit('ercspn_l extobl_l intobl_l');
    MuscleGroups.back_extrot = strsplit('ercspn_l extobl_r intobl_l');
    MuscleGroups.back_flex = strsplit('extobl_l extobl_r intobl_l intobl_r');
    
    % Redefine these after adding back muscles in. 
    muscle_group_names = fieldnames(MuscleGroups);
    n_groups = length(muscle_group_names);

    % Gain access to the appropriate data.
    cmc = result.CMC{foot, context, assistance};
    weight = result.Properties.Weight;

    % Create cell array to hold temporary results, and a temporary variable
    % to store the total average metabolic power.
    n_cmcs = vectorSize(cmc);
    temp{n_groups, n_cmcs} = {};

    for i=1:n_groups
        % Calculate the metrics and store the results. 
        for j=1:n_cmcs
            temp{i,j} = calculateAvgGroupPowers(cmc{j}, ...
                MuscleGroups.(muscle_group_names{i}), weight);
        end

        % Store results properly and clear temp variable. 
        result.MetricsData.(muscle_group_names{i}){ ...
            foot, context, assistance} = temp(i,:);
    end
    
    % Total power.
    total{n_cmcs} = {};
    for i=1:n_cmcs
        total{i} = sum(cell2mat(temp(:,i)));
    end
    
    result.MetricsData.TotalAvgPower{foot, context, assistance} = total;

end

