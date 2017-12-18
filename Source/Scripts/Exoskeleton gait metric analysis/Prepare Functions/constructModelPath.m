function path = constructModelPath(root, subject, assistance)
% This function returns the path to the subject specific model used during 
% the ROBIO 2017 submission. 

    if assistance == 1
        model = 'no_APO';
    else
        model = 'APO';
    end
    
    path = [root '\S' num2str(subject) '\Scaling\' model '.osim'];
    
end