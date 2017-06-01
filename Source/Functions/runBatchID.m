function ID_array = runBatchID(model, ik_folder, grf_folder, results, load)
% Run a batch of the ID algorithm. 

% Handle input arguments.
if nargin < 4 || nargin > 5
    error('Incorrect number of arguments.');
elseif nargin == 4
    load = 'normal';
end

% If the desired results directory exists already, get its full path. If
% not, create it and get its full path. 
if exist([pwd '/' results], 'dir')
    results = getFullPath(results);
else
    results = createUniqueDirectory(results);
end

% Obtain the files in the ik and grf folders. 
ik_struct = dir([ik_folder '/*.mot']);
grf_struct = dir([grf_folder '/*.mot']);

% Check we have the same number of files. 
if size(ik_struct,1) ~= size(grf_struct,1) 
    error('Number of IK and GRF files do not match.');
end

% Create a cell array to hold the ID results. 
ID_array{size(ik_struct,1)} = {};

% Iterate over the files doing ID and storing the results each time.
for i=1:size(ik_struct,1)
    Trial = OpenSimTrial(model, ...
        [ik_folder '/' ik_struct(i,1).name], load, ...
        [grf_folder '/' grf_struct(i,1).name], [results '/' num2str(i)]); 
    ID_array{i} = Trial.runID();
end

end

