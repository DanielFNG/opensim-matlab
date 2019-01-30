function data_object = Data(varargin) 
% Convenience method for opening or creating TRC/MOT/STO Data objects.
%
% Ordered arguments are: filename, header, labels, values.
% Supports nargin == 1 or nargin == 4.
% If nargin == 1: loads from filename.
% If nargin == 4: assigns data provided and sets filename manually for output.

if nargin == 1 || nargin == 4
    [~, ~, ext] = fileparts(varargin{1});
    if strcmpi(ext, '.trc')
        data_object = TRCData(varargin{:});
    elseif strcmpi(ext, '.mot') 
        data_object = MOTData(varargin{:});
    elseif strcmpi(ext, '.sto')
        data_object = STOData(varargin{:});
    else
        error('Filetype not recognised.');
    end
else
    error('Incorrect number of arguments to Data method.');
end

end
