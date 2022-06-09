function runSetup()
% Sets the 'OPENSIM_MATLAB_HOME' environment variable and adds the 
% required source code directories to the Matlab path.

% Root dir - main directory
root_dir = fileparts(pwd);

% Add the OPENSIM_MATLAB_HOME environment variable
createEnvironmentVariable('OPENSIM_MATLAB_HOME', root_dir);

% Setup logging
prepareOpenSimLogDir();

% Set the environment variable for the current session (necessary so users
% don't have to restart Matlab).
setenv('OPENSIM_MATLAB_HOME', root_dir);

% Modify the Matlab path to include the source folder.
path = genpath([root_dir filesep 'Source']);
addPathToStartup(path);

end
