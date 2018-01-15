function fullPath = getFullPath( path )
% Gets full system path from relative path. 
%   Assumes the path given is either already full or relative to the
%   CURRENT DIRECTORY. Also makes the assumption that if the path has an
%   extension, it is a file, if not it is a directory. 
%
%   For the time being also assumes that we are in the C drive...

    if path(2) == ':'
        fullPath = path;
    else
        [pathstr, name, ext] = fileparts(path);
        current = pwd;
        if isempty(ext)
            if (exist(path, 'dir') == 7)
                cd(path);
                fullPath = pwd;
            else
                % Handle the case where you want a path to a directory that
                % doesn't exist yet.
            end
        else
            if ~isempty(pathstr)
                cd(pathstr)
            end
            fullPath = [pwd '\' name ext];
        end
        cd(current);
    end

end

