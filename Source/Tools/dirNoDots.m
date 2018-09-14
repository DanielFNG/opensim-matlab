
% Access files and subdirectories in a directory without '.' or '..' entries.
function d = dirNoDots(directory)

d = dir(directory);
d = d(~ismember({d.name}, {'.', '..'}));

end