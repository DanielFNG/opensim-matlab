function scaled_vector = stretchVector(input_vector, desired_size)
% Stretch/compress a vector to a specified size using linear interpolation.

    if ~isvector(input_vector)
        error('Input must be vector.');
    end
    
    len = length(input_vector);
    x = 1:len;
    z = 1:(len - 1)/(desired_size - 1):len;
    scaled_vector = interp1(x, input_vector, z);
end

