function adjustModel(input, output, human, markers, grf, results, n)

    if nargin < 7
        n = 2;
    end

    % Create an initial ost & adjust it.
    initial = OpenSimTrial(input, markers, results, grf);
    initial.run('IK');
    initial.performModelAdjustment('torso', output, human);
    
    % Run adjustment 2 further times on the produced model.
    for i=1:n
        adjustment = OpenSimTrial(output, markers, results, grf);
        adjustment.run('IK');
        adjustment.performModelAdjustment('torso', output, human);
    end
    
    % Finally, ensure that the metabolics probe is still switched on.
    import org.opensim.modeling.Model
    osim = Model(output);
    probes = osim.getProbeSet();
    probe = probes.get(0);
    probe.setDisabled(false);
    osim.print(output);

end