function result = prepareBodyKinematicsFromFile(...
    root, subject, foot, context, assistance, result)
% This function obtains the necessary paths to read in BodyKinematics 
% Analysis files and store them as data objects. 
%
% This is designed to be passed as a function handle to the processData
% function. 

% Define some strings.
p1 = 'Analysis_BodyKinematics_';
p2 = '_global.sto';

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
bk_path = [grf_path filesep 'BodyKinematics_Results' filesep];

% Identify the folders in the correct path.
files = dir(bk_path);
is_folder = [files.isdir] & ...
    ~strcmp({files.name},'.') & ~strcmp({files.name}, '..');
folders = files(is_folder);

% Create cell arrays of the appropriate size.
positions{vectorSize(folders)} = {};
velocities{vectorSize(folders)} = {};
accelerations{vectorSize(folders)} = {};

% Read in the BodyKinematics analyses appropriately.
for i=1:vectorSize(folders)
    positions{i} = Data([bk_path folders(i,1).name filesep p1 'pos' p2]);
    velocities{i} = Data([bk_path folders(i,1).name filesep p1 'vel' p2]);
    accelerations{i} = ...
        Data([bk_path folders(i,1).name filesep p1 'acc' p2]);
end

result.BodyKinematics.positions{foot, context, assistance} = positions;
result.BodyKinematics.velocities{foot, context, assistance} = velocities;
result.BodyKinematics.accelerations{foot, context, assistance} = ...
    accelerations;
    
