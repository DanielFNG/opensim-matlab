function adjustModel(input, output, human, markers, grf, results, n)

    if nargin < 7
        n = 2;
    end

    % Create an initial ost & adjust it.
    initial = OpenSimTrial(input, markers, results, grf);
    initial.run('IK');
    initial.performModelAdjustment('torso', output, human);
    
    % Run adjustment n further times on the produced model.
    for i=1:n
        % Create temporary copy of output.
        [folder, ~, ~] = fileparts(output);
        temp = [folder filesep 'temp.osim'];
        copyfile(output, temp);
        adjustment = OpenSimTrial(temp, markers, results, grf);
        adjustment.run('IK');
        adjustment.performModelAdjustment('torso', output, human);
        delete(temp);
    end
    
    % Open up the produced model
    import org.opensim.modeling.Model
    osim = Model(output);
    
    % Ensure any metabolics probes are still switched on
    probes = osim.getProbeSet();
    n_probes = probes.getSize();
    for i = 1:n_probes
        probe = probes.get(i - 1);
        if ~probe.isEnabled()
            probe.setEnabled(true);
        end
        osim.print(output);
    end
    
    % Print the resultant model
    osim.print(output);

end