function result = loadSubject(root, subject)

    filename = [root filesep 'subject' int2str(subject) '.mat'];
    result = load(filename, 'result');
end