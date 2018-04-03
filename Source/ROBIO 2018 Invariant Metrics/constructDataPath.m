function path = constructDataPath(root, subject, foot, context, assistance)
% This function returns the path to the folder containing the data from the
% ROBIO 2017 submission from the given parameters, by making assumptions
% about the structure of the data directory. 

    if foot == 1 
        side = 'right';
    else
        side = 'left';
    end
    
    if assistance == 1
        level = 'NE';
    elseif assistance == 2
        level = 'ET';
    else
        level = 'EA';
    end
    
    path = [root '\S' num2str(subject) '\dynamicElaborations\' side ...
        filesep level num2str(context)];
    
end