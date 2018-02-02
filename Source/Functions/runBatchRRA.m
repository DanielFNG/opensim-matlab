function RRA_array = runBatchRRA(...
    model, ik_folder, grf_folder, results, load)
% Run a batch of the RRA algorithm (no adjustment). 
%   Uses the input model file to run RRA without adjustment on a set of
%   input data files.
%
%   1) A model file.
%   2) A folder of IK files on which to do RRA without adjustment. 
%   3) The corresponding folder of GRF files.
%   4) Results folder.
%   5) (Optional - default 'normal') load type.
%
%   The files in each folder can have any name but must have an integer
%   suffix which begins at 1, i.e. 'ik1.mot', 'ik2.mot', etc.
%
%   Output is an array of RRA Results objects.
%
%   RRA is run from start to end of the input files. Also, the results are
%   saved in folders within results which match the numbering of the input
%   files. 

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

% Obtain the files in the ik and grf folders. 
ik_struct = dir([ik_folder '/*.mot']);
grf_struct = dir([grf_folder '/*.mot']);

% Check we have the same number of files. 
if size(ik_struct,1) ~= size(grf_struct,1) 
    error('Number of IK and GRF files do not match.');
end

% Create a cell array to hold the RRA results.
RRA_array{size(ik_struct,1)} = {};

% Iterate over the files doing RRA without adjustment and storing the 
% results each time.
for i=1:size(ik_struct,1)
    Trial = OpenSimTrial(model, ...
        [ik_folder '/' ik_struct(i,1).name], load, ...
        [grf_folder '/' grf_struct(i,1).name], [results '/' num2str(i)]);
    if nargout == 1
        RRA_array{i} = Trial.runRRA();
    else
        Trial.runRRA();
    end
    % For convenience when later doing ID etc, copy the kinematics file in
    % to one folder.
    rra_folder = getSubfolders([results filesep num2str(i)]);
    positions = [results filesep num2str(i) filesep ...
        rra_folder(1).name filesep 'RRA_Kinematics_q.sto'];
    copyfile(positions,[results '/' 'RRA_q_' num2str(i) '.sto']);
end

end

