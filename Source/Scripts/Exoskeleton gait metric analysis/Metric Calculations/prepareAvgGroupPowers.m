function result = prepareAvgGroupPowers(foot, context, assistance, result)

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

