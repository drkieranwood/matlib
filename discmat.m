function [ Ad,Bd,Cd,Dd ] = discmat( Ac,Bc,Cc,Ts,plot_on )
%DISCMAT Create discrete versions of continuous state-space matrices.
%   Applies the matrix exponential method of creating discrete state-space
%   system matrices. The inputs are the A,B,C matrices and D is assumed
%   zero. Ts is the sampling inteval. plot_on controls if a step comparison
%   of the continuous and discrete systems should be displayed.
%   The sizes of the continuous matrices must be consistient and Ts cannot
%   be negative (but can be zero!).


%Check the number of input arguments
if (nargin<4)
    error('discmat: Not enough input arguments.');
end
if (nargin<5)
    plot_on = 1; 
end


%Check the matrices are of the correct sizes.
[a b] = size(Ac);
if (a~=b)
    error('discmat: Ac must be square.');
end
numSta = a;

[a b] = size(Bc);
if (a~=numSta)
    error('discmat: Bc must have as many rows as Ac.');
end
numInp = b;

[a b] = size(Cc);
if (b~=numSta)
    error('discmat: Cc must have as many columns as Ac.');
end
numOut = a;


%Check Ts
if (Ts<0)
    error('discmat: Ts must be non-negative definite.');
end


%Perform the discretisation
%Create the augmented matrix
CCC = [Ac Bc ; zeros(numInp,numSta) zeros(numInp,numInp)];

%Apply the exponential
DDD = expm(CCC*Ts);

%Split the result
Ad = DDD(1:numSta,1:numSta);
Bd = DDD(1:numSta,numSta+1:numSta+numInp);
Cd = Cc;
Dd = zeros(numOut,numInp);

%Perform simulation comparison
if plot_on
    Dc = Dd;
    ssc = ss(Ac,Bc,Cc,Dc);
    ssd = ss(Ad,Bd,Cd,Dd,Ts);
    h1 = figure('name','Cont. Disc. Comp.');
    hold on;
    step(ssc,2);
    step(ssd,2);
end


end

