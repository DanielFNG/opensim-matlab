function result = prepareBatchIK(root, subject, foot, context, assistance, output_dir)

    data_path = ...
        constructDataPath(root, subject, foot, context, assistance);
    model_path = constructModelPath(root, subject, assistance);
    
    if nargin == 5
        output_dir = [data_path '\IK_Results'];
    elseif nargin ~= 6
        error('Incorrect number of arguments to prepareBatchIK.');
    end
    
    [result.IK_array, result.Input_Markers_array, ...
        result.Output_Markers_array] = ...
        runBatchIK(model_path, data_path, output_dir);
    
end