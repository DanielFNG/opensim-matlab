function new_directory = createUniqueDirectory( desired_directory )
%Create non-duplicate directories.
%   Try to create the desired results directory, but if it already exists
%   keep appending successive integers until you find one which doesn't
%   exist and create that instead. Return new directory name.

    attempt = desired_directory;
    append = 0;
    while true
        % I would like this to be getFullPath(attempt) in case we are not
        % in a directory where a relative path makes sense. This requires a
        % change to getFullPath which I haven't implemented yet, there's a
        % note in a comment there. 
        if exist([pwd filesep attempt], 'dir')
            display(['Directory already exists. Appending integer ' ...
                'to prevent loss of data.']);
            append = append + 1;
            attempt = [desired_directory num2str(append)];
        else
            break
        end
    end
    mkdir(attempt);
    new_directory = getFullPath(attempt);

end

