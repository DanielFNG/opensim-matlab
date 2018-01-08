function [RRA_adjustment, RRA_array] = adjustAndRunBatchRRA(...
    scaled_model,ik,grf,ik_folder,grf_folder, results, load)
%Function for running the RRA algorithm in batch form, first adjusting for 
%dynamic inconsistency. 
%   Uses input kinematic and GRF data to perform RRA and calculate a
%   modified model file. Then, uses this model file to run RRA without
%   adjustment on a set of input data files. 
%
%   1) A scaled model file.
%   2) An IK file on which do do RRA with adjustment. 
%   3) A corresponding GRF file. 
%   4) A folder of IK files on which to do RRA without adjustment.
%   5) The corresponding folder of GRF files.
%   6) Results folder.
%   7) (Optional) load type. 
%
%   The files in each folder can have any name but must have an integer
%   suffix which begins at 1, i.e. 'ik1.mot, ik2.mot, ...' etc. 
%
%   Output is an array of RRAResults objects and an RRAResults object for the
%   for the adjusted trial.

% Handle input arguments. 
if nargin < 6 || nargin > 7
    error('Incorrect number of arguments.');
elseif nargin == 6
    load = 'normal';
end

% If the desired results directory exists already, get its full path. If
% not, create it and get its full path. 
if exist([pwd '/' results], 'dir')
    results = getFullPath(results);
else
    results = createUniqueDirectory(results);
end

% Run RRA with adjustment on this trial. 
RRA_adjustment = adjustmentRRA(scaled_model,ik,grf,results,load);

% Run a batch RRA on the rest of the data using the adjusted model.
RRA_array = runBatchRRA(RRA_adjustment.getAdjustedModel(), ik_folder, ...
    grf_folder, results, load);

end

