function data_object = Data(varargin) 
% Convenience method for opening or creating TRC/MOT/STO Data objects.
%
% Two possibilities for varargin: 1) (filename) 
%                                 2) (header, labels, values)
%
% If nargin == 1: loads from filename
% If nargin == 3: assigns properties as provided  

[~, ~, ext] = fileparts(varargin{1});
if strcmpi(ext, '.trc')
    data_object = TRCData(varargin{:});
elseif strcmpi(ext, '.mot') 
    data_object = MOTData(varargin{:});
elseif strcmpi(ext, '.sto')
    data_object = STOData(varargin{:});
elseif strcmpi(ext, '.txt')
    data_object = TXTData(varargin{:});
else
    error('Filetype not recognised.');
end

end
