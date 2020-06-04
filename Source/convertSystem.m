function data_out = convertSystem(data_in, system)
% Convert cartesian data to the generic OpenSim co-ordinate system. 
%   The generic OpenSim co-ordinates are as follows, where the origin is
%   centred on the the subject:
%       Forward: +x
%       Up: +y
%       Right: + z
%   Using a description of the co-ordinate system data_in is in, of a
%   similar form to the above e.g. the axis forward, right & up from the
%   subject, we can transform the data to be in OpenSim co-ordinates.
%
%   Inputs:
%           - data_in : a 3 x N array, for some N. N x 3 is also supported
%           - system : a struct with fields 'forward', 'up' & 'right', each
%                      containing a character array of length 2, the first
%                      character being '+' or '-' and the second being one
%                      of 'x', 'y' and 'z'
%   Output:
%           - data_out : the input data converted in to OpenSim
%                        co-ordinates

    % Convert to 3 x N if necessary.
    if size(data_in, 1) ~= 3
        data_in = transpose(data_in);
        transp = true;
    else
        transp = false;
    end
        
    % Create output arrays.
    data_out = zeros(size(data_in));

    % Identify system parameters.
    [mx, ix] = convertSystemIdentifier(system.Forward);
    [my, iy] = convertSystemIdentifier(system.Up);
    [mz, iz] = convertSystemIdentifier(system.Right);

    % Convert coordinate systems.
    data_out(1, :) = mx*data_in(ix, :);
    data_out(2, :) = my*data_in(iy, :);
    data_out(3, :) = mz*data_in(iz, :);
    
    % Re-transpose if necessary.
    if transp
        data_out = transpose(data_out);
    end

end