function d = dirNoDots(directory)

d = dir(directory);
d = d(~ismember({d.name}, {'.', '..'}));

end