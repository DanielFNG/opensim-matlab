function configureExopt()
% Sets the 'EXOPT_HOME' environment variable and adds the full Exopt tree
% to the matlab path. Not sure if this is necessarily the best way of doing
% it so might revisit this. In fact, I think I should definitely change it
% to not include directories which are likely to change i.e. results
% directories.

% Move to the 'main' exopt directory. 
cd('..');

% Modify startup.m file so that we have EXPORT_HOME environment variable
% for future sessions. 
% Checks if startup.m file exists, if not one is created in matlabroot if we 
% have access to it, or to the 'Setup/startup' folder of this directory 
% otherwise, if yes the existing one is appended to.
if isempty(which('startup.m'))
    [fileID,~] = fopen([matlabroot filesep 'startup.m'], 'w');
    if fileID == -1
        display(['Attempted to create startup.m file in matlabroot, but' ...
            ' access was denied. Created it in setup\startup folder instead.' ...
            ' Consider changing this as having the startup.m file tied' ...
            ' to a repository can be undesirable.']);
        mkdir(['Setup' filesep 'startup']);
        [fileID,~] = fopen(['Setup' filesep 'startup' filesep 'startup.m'], 'w');
        flag = 1;
    else
        flag = 0;
    end
    fprintf(fileID, '%s', ['setenv(''EXOPT_HOME'', ''' pwd ''');']);
else
    fileID = fopen(which('startup.m'), 'a');
    if fileID == -1
        display(['Attempted to open existing startup.m file in ' ...
            'matlabroot, but access was denied. Please rerun this ' ...
            'script after running Matlab as an administrator.']);
        cd('Setup');
        return
    end
    fprintf(fileID, '\n%s', ['setenv(''EXOPT_HOME'', ''' pwd ''');']);
	flag = -1;
end

% Fix and save the location of the OpenSim err.log and out.log files. 
fprintf(fileID, '\n%s', 'current_dir = pwd;');
fprintf(fileID, '\n%s', 'cd(getenv(''EXOPT_HOME''));');
fprintf(fileID, '\n%s', 'cd(''Logs'');');
fprintf(fileID, '\n%s', 'import org.opensim.modeling.Model');
fprintf(fileID, '\n%s', 'test = Model();');
fprintf(...
    fileID, '\n%s', 'setenv(''EXOPT_OUT'', [pwd filesep ''out.log'']);');
fprintf(fileID, '\n%s', 'cd(current_dir)');
fprintf(fileID, '\n%s', 'clear;');

% Close the startup file.
fclose(fileID);

% Set the environment variable for the current session (necessary so users
% don't have to restart Matlab).
setenv('EXOPT_HOME', pwd);

% Modify the Matlab path to include the source folder.
addpath(genpath([getenv('EXOPT_HOME') filesep 'Source']));

% Include any additional libraries. 
addpath(genpath([getenv('EXOPT_HOME') filesep 'External' filesep ...
    'qpOASES-3.2.1' filesep 'interfaces' filesep 'matlab']));
addpath(genpath([getenv('EXOPT_HOME') filesep 'External' filesep ...
    'multiWaitbar']));
    
% Originally setup was also added to the path, but this is a terrible idea
% since this script uses the assumption of being in the setup folder!!
% Instead I added a startup folder to the setup folder and added this to
% the path only.
if flag == 1
    addpath(genpath([getenv('EXOPT_HOME') filesep 'Setup' filesep 'startup']));
elseif flag == 0
    addpath(matlabroot);
end
savepath;

% Go back to the setup folder. 
cd('Setup');

end
