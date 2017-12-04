function result = processData(handles, savename)
% This function gives programmatic access to the data files for the 
% submission to ROBIO 2017. This allows for efficient data processing.
%
% Inputs: 
%
%   handles -  cell array of function handles. These will be executed in 
%              index order in the innermost loop of this function. These
%              functions are assumed to return a struct, and to take 
%              root, subject, foot, context and assistance as required 
%              arguments.
%   savename - if specified instructs the code to save after every subject
%              and clear the previous calculations to save memory. This 
%              should be a string, and should NOT include '.mat'.
%
% Outputs:
% 
% result - a cell array containing the results from each of the executed
%          function calls

% Convenience definitions.
n_func = vectorSize(handles);

% Arrays to decide which data to look at.
subjects = [1:4, 6:8];  % Ignore missing data from subject 5. 
feet = 1:2;
contexts = 1:10;
assistance_level = 1:3;

% Create a cell array of the appropriate size to hold the results. First
% index is the function, then subject, foot, context, assistance_level.
% Choosing max rather than len to make it clearer if we have gaps (e.g.
% missing subject 5). This doesn't help when missing end points but that
% should be more obvious...
result{n_func, max(subjects), max(feet), max(contexts), ...
    max(assistance_level)} = {};

% Get the root folder using a user interface.
root = uigetdir('', 'Select directory containing subject data folders.');

% Loop over the subjects. 
for subject = subjects
    % Loop over feet. 
    for foot = feet    
        % Loop over contexts. 
        for context = contexts
            % Loop over assistance level. 
            for assistance = assistance_level
                % Loop over functions to be applied. 
                for func=1:n_func
                    result{func,subject,foot,context,assistance} = ...
                        handles{func}(...
                        root,subject,foot,context,assistance); 
                end
                
                % Display progress update. 
                fprintf(['Progress update: just completed function %u,' ...
                    ' subject %u, foot %u, context' ... 
                    ' %u, assistance %u.\n'], func, subject, foot, ...
                    context, assistance);
            end
        end
    end
    % Optionally save and clear periodically. 
    if nargin == 2
        save([savename '_subject' num2str(subject) '.mat'], 'result');
        result(:,subject,:,:,:) = {[]};
    end
end

end
