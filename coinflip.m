%Run to detect the maximum number of same flips in a row.
%Uses the rand() funtion to create number between 0:1. If it is less than
%0.5 the it is tails, else it is heads.
%
%The number of iterations can be set with maxIterations=
%The frequncy of progress messages can be set with percentStep=
%    use 1 for every 1%, 10 for every 10% complete etc..
%

maxIterations = 100000000;
percentStep = 1;

%========================
%Setup
%========================
clc;
maxT = 0;
maxH = 0;
Tcount = 0;
Hcount = 0;
percentCount = 0;
initT = cputime;


%========================
%Iterate
%========================
for i=1:1:maxIterations
    a = rand(1);
    if (a<0.5)
        Hcount = 0;
        Tcount = Tcount + 1;
        if (Tcount > maxT)
            maxT = Tcount;
        end
    else
        Tcount = 0;
        Hcount = Hcount + 1;
        if (Hcount > maxH)
            maxH = Hcount;
        end
    end
    if (((i*100)/maxIterations) > percentStep*percentCount)
        timeToNow = cputime-initT;
        timeToForWhole = (timeToNow/(percentStep*percentCount))*100;
        timeToFinish = timeToForWhole-timeToNow;
        disp([percentStep*percentCount timeToFinish/60]);
        percentCount = percentCount + 1;
    end
    
end
disp([100 0.0]);
clc;


%========================
%Display results
%========================
disp('Max Heads');
maxH
disp('Max Tails');
maxT
disp('Duration');
dur = cputime-initT