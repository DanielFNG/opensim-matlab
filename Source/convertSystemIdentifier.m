function [multiplier, index] = convertSystemIdentifier(id)
% Helper function for convertSystem.
%
% Converts an identifier like '+x' in to a multiplier - +1 for '+' and -1
% for '-' and the correct data index e.g. 1 for x, 2 for y and 3 for z. 

if strcmp(id(1), '+')
    multiplier = 1;
elseif strcmp(id(1), '-')
    multiplier = -1;
else
    error('Invalid system identification.');
end

switch lower(id(2))
    case 'x'
        index = 1;
    case 'y'
        index = 2;
    case 'z'
        index = 3;
end

end