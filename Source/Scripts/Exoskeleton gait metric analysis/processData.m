function result = processData(...
    root, subjects, feet, contexts, assistances, handles, savename)
% This function gives programmatic access to the data files for the 
% submission to ROBIO 2017. This allows for efficient data processing.
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

% Loop over the subjects. 
for subject = subjects
    % Loop over feet. 
    for foot = feet    
        % Loop over contexts. 
        for context = contexts
            % Loop over assistance level. 
            for assistance = assistances
                % Loop over functions to be applied. 
                for func=1:n_func
                    evalc([...
                        'result{func,subject,foot,context,assistance}'... 
                        ' = handles{func}('...
                        'root,subject,foot,context,assistance)']);
                    
                    % Display progress update.
                    fprintf(['Progress update: just completed subject'...
                        ' %u, foot %u, context %u, assistance %u, '...
                        'function %u.\n'], subject, foot, ...
                        context, assistance, func);
                end
            end
        end
    end
    % Optionally save and clear periodically. 
    if nargin == 7
        save([savename '\subject' num2str(subject) '.mat'], 'result');
        result(:,subject,:,:,:) = {[]};
    end
end

% Print a finishing message.
fprintf('Data processing complete.\n\n');

end
