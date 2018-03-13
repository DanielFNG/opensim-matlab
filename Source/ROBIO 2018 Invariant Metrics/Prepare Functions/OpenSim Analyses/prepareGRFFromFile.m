function result = prepareGRFFromFile(...
    root, subject, foot, context, assistance, result)
% This function obtains the necessary paths to read in GRF files and store
% them as data objects.
%
% This is designed to be passed as a function handle to the processData
% function.

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);

% Identify the grf files.
grf_struct = dir([grf_path filesep '*.mot']);

% Create a cell array of the appropriate size.
temp{vectorSize(grf_struct)} = {};

% Read in each grf file as a Data object. 
for i=1:vectorSize(grf_struct)
	temp{i} = Data([grf_path filesep grf_struct(i,1).name]);
end

result.GRF{foot, context, assistance} = temp;

end

