function configureExopt()
% Sets the 'EXOPT_HOME' environment variable and adds the full Exopt tree
% to the matlab path. Not sure if this is necessarily the best way of doing
% it so might revisit this. In fact, I think I should definitely change it
% to not include directories which are likely to change i.e. results
% directories. 

% Move to the 'main' exopt directory. 
cd('..');

% Modify startup.m file so that we have EXPORT_HOME environment variable
% for future sessions, and to automatically import the OpenSim Matlab API. 
% Checks if startup.m file exists, if not one is created, if yes the existing 
% one is appended to.
if isempty(which('startup.m'))
    [fileID,err] = fopen('Setup/startup.m', 'w');
    fprintf(fileID, '%s', ['setenv(''EXOPT_HOME'', ''' pwd ''');']);
else
    fileID = fopen(which('startup.m'), 'a');
    fprintf(fileID, '\n%s', ['setenv(''EXOPT_HOME'', ''' pwd ''');']);
end
fclose(fileID);

% Set the environment variable for the current session (necessary so users
% don't have to restart Matlab).
setenv('EXOPT_HOME', pwd);

% Modify the Matlab path to include all exopt directories. 
addpath(genpath([getenv('EXOPT_HOME') filesep 'Source']));
savepath;

% Go back to the setup folder. 
cd('Setup');

end

