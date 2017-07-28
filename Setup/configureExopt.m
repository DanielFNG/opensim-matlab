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
    fprintf(fileID, '\n%s', ['setenv(''EXOPT_HOME'', ''' pwd ''');']);
end
fclose(fileID);

% Set the environment variable for the current session (necessary so users
% don't have to restart Matlab).
setenv('EXOPT_HOME', pwd);

% Modify the Matlab path to include the source folder.
addpath(genpath([getenv('EXOPT_HOME') filesep 'Source']));

% Include any additional libraries. 
addpath(genpath([getenv('EXOPT_HOME') filesep 'External' filesep ...
    'qpOASES-3.2.1' filesep 'interfaces' filesep 'matlab']));
    
% Originally setup was also added to the path, but this is a terrible idea
% since this script uses the assumption of being in the setup folder!!
% Instead I added a startup folder to the setup folder and added this to
% the path only.
if flag
    addpath(genpath([getenv('EXOPT_HOME') filesep 'Setup' filesep 'startup']));
else
    addpath(matlabroot);
end
savepath;

% Go back to the setup folder. 
cd('Setup');

end
