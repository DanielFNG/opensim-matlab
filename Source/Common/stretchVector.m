function scaled_vector = stretchVector(input_vector, desired_size)
% Given a vector of so many elements, stretch/compress it to a specified
% desired size. Inputs should be vectors so Nx1 arrays.
    x = 1:1:size(input_vector,1);
    z = 1:1:desired_size;
    scaled_vector = interp1(x, input_vector, z);
end

