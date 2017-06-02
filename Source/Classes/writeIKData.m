% Write the IK.mot results in to appropriate locations. This is only
% necessary for subject 1, and for left foot, and for non steady state. 

root = ['C:\Users\Daniel\University of Edinburgh\OneDrive - University '...
    'of Edinburgh\Exoskeleton metrics data\Data files\'];

subject_path = [root 'S1\17-05-18\dynamicElaborations\leftNon-StSt'];

for assistance = 1:3
    if assistance == 1
        path = [subject_path '\NE'];
    elseif assistance == 2
        path = [subject_path '\ET'];
    else
        path = [subject_path '\EA'];
    end
    for context = 1:2:9
        if context == 1
            for cycle = 1:5
                IK_array{1,assistance,2,context}{cycle}.writeToFile([path num2str(context) '\ik' num2str(cycle) '.mot'], 1, 1);
            end
        else
            for cycle = 1:2
                IK_array{1,assistance,2,context}{cycle}.writeToFile([path num2str(context) '\ik' num2str(cycle) '.mot'], 1, 1);
            end
        end
    end
end

        