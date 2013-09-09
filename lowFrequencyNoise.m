%Script to ouput low frequency sound
%K Wood
%20/04/2011

close all;
clear all; 
clc;

%440 A
if 0
minFreq = 440;
maxFreq = 440;
end

%Middle C
if 1
minFreq = 261.626;
maxFreq = 261.626;
end

%Something low
if 0
minFreq = 50;
maxFreq = 50;
end

if minFreq == maxFreq
    maxFreq = maxFreq+0.001;
end


duration = 5.0;
amplitude = 1.0;  %max 2.0;


sf = 22050;                 % sample frequency (Hz)
d = duration;               % duration (s)
n = sf * d;                 % number of samples
s = (1:n) / sf;             % sound data preparation
cf = [minFreq:(maxFreq-minFreq)/length(s):maxFreq];          % carrier frequency (Hz)
s = amplitude.*sin(2 .* pi .* cf(1:(length(cf)-1)) .* s);    % sinusoidal modulation
sound(s, sf);               % sound presentation
pause(d + 0.5);             % waiting for sound end


