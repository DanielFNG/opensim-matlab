% Convert paths to absolute format. 
function varargout = rel2abs(varargin)

for i=1:length(varargin)
    if ~java.io.File(varargin{i}).isAbsolute
        varargout{i} = fullfile(pwd, varargin{i});
    end
end
    
end

