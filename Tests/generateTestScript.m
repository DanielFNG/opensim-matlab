% Open a file for writing
fileID = fopen('testOsimTools.m', 'w');

% Parameters
root = [getenv('OPENSIM_MATLAB_HOME') filesep 'Tests'];
test = [root filesep 'Test Data'];
true = [root filesep 'True Data'];
file_types = {'.trc', '.mot', '.sto'};

% Get the directories in the test & true data folders
[~, test_dirs] = dirNoDots(test);
[~, true_dirs] = dirNoDots(true);

% Loop over every test file
for i = 1:length(test_dirs)
    [~, test_files] = dirNoDots(test_dirs{i});
    [~, true_files] = dirNoDots(true_dirs{i});
    for j = 1:length(test_files)
        [~, ~, ext] = fileparts(test_files{j});
        if any(strcmp(ext, file_types))
            % Create an entry in the test script for each individual test
            [~, name, ~] = fileparts(test_dirs{i});
            fprintf(fileID, '%s %s %i\n', '%%', name, j);
            fprintf(fileID, 'assert(Data(''%s'') == Data(''%s''));\n', ...
                test_files{j}, true_files{j});
            fprintf(fileID, '\n');
        end
    end
end

% Close the file
fclose(fileID);