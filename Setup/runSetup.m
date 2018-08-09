function runSetup()
% Sets the 'OPENSIM_MATLAB_HOME' environment variable and adds the 
% required source code directories to the Matlab path.

% Move to the 'main' opensim-matlab directory. 
cd('..');

% Modify startup.m file so that we have OPENSIM_MATLAB_HOME environment variable
% for future sessions. 
% Checks if startup.m file exists, if not one is created in matlabroot if we 
% have access to it, or to the 'Setup' folder of this directory 
% otherwise, if yes the existing one is appended to.
if isempty(which('startup.m'))
    [fileID,~] = fopen([matlabroot filesep 'startup.m'], 'w');
    if fileID == -1
        disp(['Attempted to create startup.m file in matlabroot, but' ...
            ' access was denied. Created it in setup folder instead.' ...
            ' Consider changing this as having the startup.m file tied' ...
            ' to a repository can be undesirable.']);
        mkdir(['Setup' filesep 'startup']);
        [fileID,~] = ...
            fopen(['Setup' filesep 'startup' filesep 'startup.m'], 'w');
        flag = 1;
    else
        flag = 0;
    end
    fprintf(fileID, '%s', ['setenv(''OPENSIM_MATLAB_HOME'', ''' pwd ''');']);
else
    fileID = fopen(which('startup.m'), 'a');
    if fileID == -1
        disp(['Attempted to open existing startup.m file in ' ...
            'matlabroot, but access was denied. Please rerun this ' ...
            'script after running Matlab as an administrator.']);
        cd('Setup');
        return
    end
    fprintf(fileID, '\n%s', ['setenv(''OPENSIM_MATLAB_HOME'', ''' pwd ''');']);
	flag = -1;
end

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

% Set the environment variable for the current session (necessary so users
% don't have to restart Matlab).
setenv('OPENSIM_MATLAB_HOME', pwd);

% Modify the Matlab path to include the source folder.
env = getenv('OPENSIM_MATLAB_HOME');
addpath(genpath([env filesep 'Source']));
    
% Originally setup was also added to the path, but this is a terrible idea
% since this script uses the assumption of being in the setup folder!!
% Instead I added a startup folder to the setup folder and added this to
% the path only.
if flag == 1
    addpath(genpath([env filesep 'Setup' filesep 'startup']));
elseif flag == 0
    addpath(matlabroot);
end
savepath;

% Go back to the setup folder. 
cd('Setup');

end
