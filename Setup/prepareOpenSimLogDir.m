function prepareOpenSimLogDir()

    fileID = openStartupFile();
    
    % Fix and save the location of the OpenSim err.log and out.log files. 
    fprintf(fileID, '\n%s', 'current_dir = pwd;');
    fprintf(fileID, '\n%s', 'cd(getenv(''OPENSIM_MATLAB_HOME''));');
    fprintf(fileID, '\n%s', 'cd(''Logs'');');
    fprintf(fileID, '\n%s', 'import org.opensim.modeling.Model');
    fprintf(fileID, '\n%s', 'test = Model();');
    fprintf(fileID, '\n%s', ['setenv(''OPENSIM_MATLAB_OUT'', '...
        '[pwd filesep ''out.log'']);']);
    fprintf(fileID, '\n%s', 'cd(current_dir)');
    fprintf(fileID, '\n%s', 'clear;');

    % Close the startup file.
    fclose(fileID);

end