function result = prepareIKFromFile(...
    root, subject, foot, context, assistance, result)
% This function obtains the necessary paths to read in ID files and store
% them as data objects.
%
% This is designed to be passed as a function handle to the dataLoop
% function.

% Define some strings. 
p1 = 'ik';
p2 = '.mot';
f1 = 'MarkerData';
f2 = 'ik_model_marker_locations.sto';
f3 = 'raw_marker_locations.trc';

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
ik_path = [grf_path filesep 'IK_Results' filesep];

% Identify the IK files. 
ik_struct = dir([ik_path '*.mot']);

% Create cell arrays of the appropriate size.
size = vectorSize(ik_struct);
ik{size} = {};
raw{size} = {};
output{size} = {};

% Read in files as data objects.
for i=1:size
    ik{i} = Data([ik_path p1 num2str(i) p2]);
    raw{i} = Data([ik_path num2str(i) f1 filesep f3]);
    output{i} = Data([ik_path num2str(i) f1 filesep f2]);
end

result.IK.IK_array{foot, context, assistance} = ik;
result.IK.Input_Markers_array{foot, context, assistance} = raw;
result.IK.Output_Markers_array{foot, context, assistance} = output;