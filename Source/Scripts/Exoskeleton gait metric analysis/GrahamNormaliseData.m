function [ Normalised_data ] = GrahamNormaliseData( data )
%NORMALISEDATA Summary of this function goes here
%   Detailed explanation goes here

data = resample(data,2,1);
Normalised_data = interpft(data,100);

end

