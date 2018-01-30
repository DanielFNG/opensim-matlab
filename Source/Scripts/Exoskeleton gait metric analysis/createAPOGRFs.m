function result = createAPOGRFs(...
    root, subject, foot, context, assistance, result)
% This function obtained the necessary paths to read in GRF files and APO
% torques and create GRF files modified to include the APO actuation. 
%
% This is designed to be passed as a function handle to the processData
% function.

% Force an error if the assistance level is not equal to 3. 
if assistance ~= 3
    error('Do NOT replace the grf files for the NE or ET cases.');
end

% Get appropriate path.
grf_path = constructDataPath(...
    root, subject, foot, context, assistance);
ik_path = [grf_path filesep 'IK_Results'];

% Identify the grf files.
ik_struct = dir([ik_path filesep '*.mot']);
grf_struct = dir([grf_path filesep '*.mot']);

% Create a cell array of the appropriate size.
temp{vectorSize(grf_struct)} = {};

for i=1:vectorSize(grf_struct)
    % Load in the right hip flexion joint angle trajectory. 
    ik = Data([ik_path filesep ik_struct(i,1).name]);
    hip = ik.getDataCorrespondingToLabel('hip_flexion_r');
   
    % Create a scaled copy of the APO  which is twice the length of
    % the hip vector. 
    apo_2_torques = stretchVector(result.APO.AvgH_RightJointAngle. ...
        (['Context' num2str(context)]), 2*vectorSize(hip));
    
    % Use cross correlation to align the 
    
end
    
    