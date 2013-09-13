function [ output_args ] = roundEpsilon( matIn , tolIn )
%ROUNDEPSILON Round all values near machine Epsilon to zero
%   If any values in matIn have an absoloute value smaller than tolIn they
%   are set to exactly zero. If tolIn is not specified 2^-52 is used.

%Check if a tolerance has been specified
if nargin<2
    tolIn = 2^(-52);
end

%Set values less than the tolerance to zero
output_args = matIn.*(abs(matIn)>tolIn);

end

