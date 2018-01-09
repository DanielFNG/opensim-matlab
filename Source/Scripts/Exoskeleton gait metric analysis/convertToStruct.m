% This script converts the output of the processData script in to a more
% manageable form. 
%
% Previous form: 
%   result{function,subject,foot,context,assistance}
% i.e. 5D cell array. 
%
% New form:
% result.
%   IK
%   RRA
%   ID
%   BodyKinematics
% each of which is a 3D cell array indexed by foot, context, assistance. 
%
% Ideally this script would be unnecessary and it would be saved this way
% initially. I will work on this later, but to avoid rerunning the entire 
% data processing code again*, this is a temporary solution. 
%
% * I would like to do this again anyway as it seemed to be having issues
% with memory, which I thought I'd accounted for but clearly haven't, at
% least not correctly. 

% Locate input data and output directory. 
root = 'C:\Users\Daniel\Dropbox\PhD\Exoskeleton Metrics\Matlab Data Files';
savedir = [root pwd 'structs'];

% If the desired results directory does not exist, create it. 
if ~exist(savedir, 'dir')
    mkdir(savedir);
end

% Make the file structure changes. 
for subject = [1:4, 6:8]
    str = loadSubject(root, subject);
    for foot = 1:2
        for context = 2:2:10
            for assistance = 1:3
                data.IK{foot,context,assistance} = ...
                    str.result{1,subject,foot,context,assistance};
                data.RRA{foot,context,assistance} = ...
                    str.result{2,subject,foot,context,assistance};
                data.ID{foot,context,assistance} = ...
                    str.result{3,subject,foot,context,assistance};
                data.BodyKinematics{foot,context,assistance} = ...
                    str.result{4,subject,foot,context,assistance};
            end
        end
    end
    % Save and clear periodically to save memory. 
    save(['subject' int2str(subject) '.mat'],'data');
    clear('str','data');
end

