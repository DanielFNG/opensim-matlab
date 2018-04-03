function [RRA_adjustment, path] = adjustmentRRA(model,ik,grf,results,load)
% Function for using RRA to adjust a model. 
%   Uses input kinematic and GRF data to perform RRA and calculate a
%   modified model file. 
%
%   1) A model file.
%   2) An IK file on which to do RRA with adjustment.
%   3) The corresponding GRF file.
%   4) Results folder. 
%   5) Optional (default = 'normal') load type. 
%
%   Output is an RRAResults object.
%
%   Results are saved in a subfolder in results called 'adjustment'. The
%   adjusted model is saved as 'model_adjusted.osim' and 
%   'model_adjusted_mass_changed.osim' in this folder. Finally, it is
%   assumed that RRA is to be run from start to end of the input files, and
%   that the torso is the segment to be adjusted. 

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

% Construct the OST for model adjustment.
save_dir = [results '/' 'adjustment'];
trial = OpenSimTrial(model,ik,load,grf,save_dir);

% Run RRA with adjustment on this trial.
[RRA_adjustment, path] = trial.runRRA('torso','model_adjusted');

end

