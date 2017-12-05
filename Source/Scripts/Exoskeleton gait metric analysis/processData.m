function result = processData(...
    root, subjects, feet, contexts, assistances, handles, savename)
% This function gives programmatic access to the data files for the
% submission to ROBIO 2017. This allows for efficient data processing.
% The multiWaitbar function by Ben Tordoff, Matlab, is used to provide 
% realtime feedback in terms of runtime. 
%
% Inputs:
%
%   subjects,
%   feet,
%   contexts,
%   assistances - arrays to decide which data to look at. For example
%                 subjects = [1:8] looks at all 8 subjects, or
%                 subjects = [1:3] would look at only the first 3.
%
%   handles -  cell array of function handles. These will be executed in
%              index order in the innermost loop of this function. These
%              functions are assumed to return a struct, and to take
%              root, subject, foot, context and assistance as required
%              arguments.
%   savename - if specified instructs the code to save after every subject
%              and clear the previous calculations to save memory. This can
%              be necessary - for example to compute the RRA's for all 8
%              subjects at once requires more than 8GB of RAM. This param
%              should be a string, and should NOT include '.mat'. It
%              specifies the path to the created save file.
%
% Outputs:
%
% result - a cell array containing the results from each of the executed
%          function calls

% Convenience definitions.
n_func = vectorSize(handles);

% Create a cell array of the appropriate size to hold the results. First
% index is the function, then subject, foot, context, assistance_level.
% Choosing max rather than len to make it clearer if we have gaps (e.g.
% missing subject 5). This doesn't help when missing end points but that
% should be more obvious...
result{n_func, max(subjects), max(feet), max(contexts), ...
    max(assistances)} = {};

% Print starting message.
fprintf('Beginning data processing.\n');

% Initialise loading bar.
id = 'MATLAB:nargchk:deprecated';   
warning('off', id);  % Supress multiWaitbar warning.
labels = {'Subject', 'Foot', 'Context', 'Assistance', 'Function'};
increments = [1/vectorSize(subjects), 1/vectorSize(feet), ...
    1/vectorSize(contexts), 1/vectorSize(assistances), ...
    1/vectorSize(handles)];
colours = {'b', 'r', 'g', 'm', 'k'};
for i=1:vectorSize(labels)
    multiWaitbar( labels{i}, 0, 'Color', colours{i}); 
end

try
    for subject = subjects
        multiWaitbar(labels{2}, 'Reset');  % Reset previous bar.
        for foot = feet
            multiWaitbar(labels{3}, 'Reset');
            for context = contexts
                multiWaitbar(labels{4}, 'Reset');
                for assistance = assistances
                    multiWaitbar(labels{5}, 'Reset');
                    for func=1:n_func
                        % Apply each function via handles. 
                        result{func,subject,foot,context,assistance} = ...
                            handles{func}(...
                            root,subject,foot,context,assistance);
                        
                        % Update loading bar.
                        multiWaitbar(...
                            labels{5}, 'Increment', increments(5));
                    end
                    multiWaitbar(...
                        labels{4}, 'Increment', increments(4));
                end
                multiWaitbar(...
                    labels{3}, 'Increment', increments(3));
            end
            multiWaitbar(labels{2}, 'Increment', increments(2));
        end
        % Optionally save and clear periodically.
        if nargin == 7
            save([savename '\subject' num2str(subject) '.mat'], 'result');
            result(:,subject,:,:,:) = {[]};
        end
        multiWaitbar(labels{1}, 'Increment', increments(1));
    end
    % Print successful message & close multiWaitbar.
    fprintf('Data processing complete.\n\n');
    multiWaitbar('CloseAll');
catch ME
    % Close multiWaitbar & throw error.
    multiWaitbar('CloseAll');
    rethrow(ME);
end
