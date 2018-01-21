function result = loadSubject(root, subject)

    var = ['subject' int2str(subject)];
    filename = [root filesep 'subject' int2str(subject) '.mat'];
    S = load(filename, var);
    result = S.(var);
end