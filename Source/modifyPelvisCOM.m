function modifyPelvisCOM(model_path, actuators_path)
% Modify pelvis COM in the copied actuators file to match input model.

    % Import OpenSim libraries & get default actuators file path.
    import org.opensim.modeling.Vec3
    import org.opensim.modeling.Model

    % Store the pelvis COM from the model file. 
    osim = Model(model_path);
    com = osim.getBodySet.get('pelvis').getMassCenter();

    % Convert the pelvis COM to a string. 
    com_string = sprintf('%s\t', num2str(com.get(0)), ...
        num2str(com.get(1)), num2str(com.get(2)));
    com_string = [' ', com_string];

    % Read in the default actuators xml and identify the body nodes. 
    actuators = xmlread(actuators_path);
    bodies = actuators.getElementsByTagName('body');

    % Change the CoM for each of FX/FY/FZ. We skip i=0 since this
    % occurs in the 'default' node. 
    for i=0:2
        bodies.item(i).getNextSibling().getNextSibling(). ...
            setTextContent(com_string);
    end

    % Rewrite the actuators file with the changes. 
    try
        xmlwrite(actuators_path, actuators);
    catch
        pause(0.5);  % Sometimes we need to wait a bit... 
        xmlwrite(actuators_path, actuators); 
    end

end