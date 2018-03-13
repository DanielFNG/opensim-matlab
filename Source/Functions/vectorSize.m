function [vec_size, type] = vectorSize(vector)
% Returns the size of a vector and optionally its type ('row' or 'column').

if ~ismatrix(vector)
    error('Input is not a vector (dimension > 2).');
elseif size(vector,1) == 1 && size(vector, 2) == 1
    vec_size = size(vector,1);
    type = 'n/a';
elseif size(vector,1) ~= 1 && size(vector, 2) ~= 1
    error('Input is not a vector (matrix).');
elseif size(vector,1) == 1
    vec_size = size(vector,2);
    if nargout > 1
        type = 'row';
    end
else
    vec_size = size(vector,1);
    if nargout > 1
        type = 'column';
    end
end

end

