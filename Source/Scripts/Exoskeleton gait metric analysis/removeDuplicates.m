% Removes the duplicate data that sometimes appeared.

for subject = 1:8
    if subject ~= 5
        for assistance = 1:3
            for foot=1:2
                for context=1:10
                    if context == 1 || mod(context,2) == 0
                        expected_size = 5;
                    else
                        expected_size = 2;
                    end
                    if size(IK_array{subject,assistance,foot,context},2) ~= expected_size
                        IK_array{subject,assistance,foot,context}(1) = [];
                        Input_Markers_array{subject,assistance,foot,context}(1) = [];
                        Output_Markers_array{subject,assistance,foot,context}(1) = [];
                    end
                end
            end
        end
    end
end

% Save the data with duplicates removed. 
save([root 'IK_Results_noDupes.mat'], 'IK_array', 'Input_Markers_array', ... 
    'Output_Markers_array');
