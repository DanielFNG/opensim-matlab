function CMC_array = runBatchCMC(...
    model, rra_folder, grf_folder, results, load)
% Run a batch of the CMC algorithm. Similar structure to runBatchRRA.

% Handle input arguments. 
if nargin < 4 || nargin > 5
    error('Incorrect number of arguments.');
elseif nargin == 4
    load = 'normal';
end

% If the desired results directory does not exist, create it.
if ~exist(results, 'dir')
    mkdir(results);
end

% Obtain the files in the RRA and GRF folders. 
rra_struct = dir([rra_folder '/*.sto']);
grf_struct = dir([grf_folder '/*.mot']);

% Create a cell array to hold the CMC results.
CMC_array{vectorSize(rra_struct)} = {};

% Iterate over the files doing CMC and storing the results.
for i=1:vectorSize(rra_struct)
    Trial = OpenSimTrial(model, ...
        [rra_folder filesep rra_struct(i,1).name], load, ...
        [grf_folder filesep grf_struct(i,1).name], [results filesep ...
        num2str(i)]);
    if nargout == 1
        CMC_array{i} = Trial.runCMC();
    else
        Trial.runCMC();
    end
end

end