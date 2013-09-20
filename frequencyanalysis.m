function [ peakFrequency ] = frequencyanalysis( inputVector , sampleRate, filterCutoff, filtHigh)
%FREQUENCYANALYSIS Perform a Fourier transform of the argument data.
%   This function analyses the given vector and plots the frequency content
%   as a power vs frequency plot. The second argument is the sampling
%   frequency and this must be constant in Hz. The third argument is optional and
%   specifies a low pass filter cut-off frequency in Hz. This applies a filter to
%   the data to remove nosie above this frequency. Note that any
%   frequencies above the Nyquist cannot be detected anyway so this filter
%   should be set lower than the Nyquist.
%
%   A high pass filter can be specified to remove low frequency drifts
%   using the 4th optional arguments to set the filter rate in Hz. Be sure
%   to check the filter is acting appropreately by comparing the original
%   and filtered data plots. A filter rate of 0.01Nyq is automatically
%   applied if no optional argument is given.
%
%   If the data has a non constant sample rate, but remains roughly
%   constant ( std(rate)< 0.2mean(rate) ) then a two column vector can be
%   supplied as data. The first column should be the sample times and the
%   second should be the sample values. The data is then interpolated into
%   a constant rate for the frequency analysis to be applied.
%
%   Note if using rate varing data, the higher frequency content will be
%   less accurate. The rate varing method is better for analysing data with high
%   sample rates which contain slow periodic components.
%   
%
%   USEAGE:
%   A = frequencyAnalysis(X,Y,Z,W)
%   Where,
%   X - a nx1 column vector [values(:)], or nx2 column vectors [time(:) values(:)]
%   Y - the sampling rate of the data in Hz
%   Z - a low pass pre-filter cut-off frequency in Hz
%   W - a high pass pre-filter cut-off frequency in Hz
%   A - The peak magnitude frequency detected in the signal
%
%   For the implementation see,
%   http://www.mathworks.co.uk/help/signal/ug/psd-estimate-using-fft.html


% A sample data vector
% sampleRate = 1000; t = linspace(0,1,1000); inputVector = cos(2*pi*100*t) + randn(size(t)) + 5*sin(2*pi*175*t);
% endt = 1; sampleRate = 1000; t = linspace(0,endt,endt*sampleRate); t(:) = t(:) + 0.0001*randn(length(t),1); inputVector = 2*cos(2*pi*100*t)+randn(size(t)) + 5*sin(2*pi*175*t) + 0.1*t;

%============================
%Check the input arguments
%============================
%The minimum number of arguments is 2. The data and the rate.
if nargin < 2
    error('FREQANA:err','Data vector and sample rate must be specified.');
end

%If no filter cut-off frequency is specified then do NOT filter the data. 
%Note the high pass at 0.01Hz is still applied.
if nargin < 3
    filter_on = 0;
    filterCutoff = 1;
else
    filter_on = 1;
    if (filterCutoff > (sampleRate/2) )
        warning('FREQANA:warn', 'Filter frequency "%4.2f" is above the Nyquist frequency "%4.2f." \nSetting filter frequency to "%3.3f." ', filterCutoff, sampleRate/2, sampleRate/2);
        filterCutoff = sampleRate/2;
    end
end



%Check the sample rate is valid (>0).
if(sampleRate <= 0)
    error('FREQANA:err','Sample rate must be positive.');
end

%Check the filter rate is valid (>0).
if(filterCutoff <= 0)
    error('FREQANA:err','Filter rate must be positive (low-pass).');
end


%============================
%Interp the data to constant time
%============================
%If the data is 1D it is assumed to be constantly time spaced at the
%specified rate. If the data has two columns then it is assumed the first
%column is the timing vector and the second is the data. The average sample
%time is calculated and used to interpolate the data.

%Check if the data has a single column
sz = size(inputVector);
dataVec = [];
if ((sz(2) == 1) && (sz(1) > 1))
    timeVec_on = 0;
    %Data has one column. Check if it is short.
    if (sz(1) < 50)
        warning('FREQANA:warn','Data vector is short, results might be inaccurate.');
    end
    
    %Set the data vector to have the fft applied.
    dataVec = inputVector;
    
elseif ((sz(2) == 2) && (sz(1) > 1))
    timeVec_on = 1;
    
    %Data has two columns. Check for shortness and interpolate.
    if (sz(1) < 50)
        warning('FREQANA:warn','Data vector is short, results might be inaccurate.');
    end
    %Find average sample interval.
    tempTimes = diff(inputVector(:,1));
    stdTimes  = std(tempTimes);
    meanTimes = mean(tempTimes);
    
    %Check if the std is within 20% of the mean. i.e is the data nearly at
    %a constant sample rate.
    if ( (stdTimes/meanTimes) > 0.2 )
        error('FREQANA:err','Sampling interval std is greater than 20percent of the mean sampling interval.'); 
    end
    
    %Interpolate the data to a constant rate at the mean sampling rate.
    newTimes  = inputVector(1,1):meanTimes:inputVector(end,1);
    newVector = interp1(inputVector(:,1),inputVector(:,2),newTimes);    
    
    %Set the data vector to have the fft applied and the new sample rate.
    sampleRate = 1/meanTimes;
    dataVec = newVector;
    
else
    %The data has too many columns so error.
    error('FREQANA:err','Input data must have one or two columns.');   
end

%Remove any bias around the mean value.
dataVec = dataVec - mean(dataVec);


%Check if data length is odd or even. If it is odd length then make even.
if (mod(length(length(dataVec)),2) ~= 0)
    dataVec = dataVec(1:end-1);
end

%============================
%Filter the data
%============================
if filter_on
    %Find normalised cut-off frequency (0:Nyquist)->(0:1)
    filtCut = filterCutoff / (sampleRate/2);
    if (filtCut > 1.0)
        filtCut = 0.98;
    end
    
    %Create a 9th order LOW pass digital filter.
    %Since the cut-off was specified relative to the Nyquist it has already
    %been discretised appropreately.
    [btemp,atemp] = butter(5,filtCut,'low');
    
    %Apply the filter using a zero phase system (filters both forwards and
    %backwards)
    dataVec = filtfilt(btemp,atemp,dataVec);    
end

%Check if a high pass filter has been specified
if nargin < 4
    filtHigh = 1.0;
    filter_on = 0;
end
%Check the filter rate is valid (>0).
if(filtHigh <= 0)
    error('FREQANA:err','Filter rate must be positive (high-pass).');
end

if filter_on
    %Create a 9th order HIGH pass digital filter.
    %Since the cut-off was specified relative to the Nyquist it has already
    %been discretised appropreately.

    %Find normalised cut-off frequency (0:Nyquist)->(0:1)
    filtCut = filtHigh / (sampleRate/2);
    [btemp,atemp] = butter(5,filtCut,'high');

    %Apply the filter using a zero phase system (filters both forwards and
    %backwards)
    dataVec = filtfilt(btemp,atemp,dataVec);   
end


%============================
%Perform the fourier analysis
%============================

%Get the number of points in the data.
N = length(dataVec);

%Discrete Fourier Transform of input.
xdftorig = fft(dataVec);

%This optioanl IF calculates the PSD. But is not needed.
if 0
    %Take only half the returned complex frequency domain values.
    %(other half is just a reflection)
    xdft = xdftorig(1:floor(N/2+1));

    %Create the PSD using the fft data.
    psdx = (1/(sampleRate*N)).*abs(xdft).^2;

    %Scale all the values (except the start and end) by 2.
    psdx(2:end-1) = 2*psdx(2:end-1);

    %The range of frequencys the fft has been performed over.
    freq = 0:sampleRate/N:sampleRate/2;
end

%The magnitude of the frequency domain data
%The factor 2/N is discussed in the documnetation
xdftmag = (2/N)*abs(fftshift(xdftorig));
xdftpha = unwrap(angle(fftshift(xdftorig)));
freq2 = [-sampleRate/2:sampleRate/(N-1):sampleRate/2];


%============================
%Plot the results
%============================

%Plot the original data and magnitude
h1 = figure('name','Frequency Content');
ax1 = subplot(2,1,1);
hold on;
if (timeVec_on == 1)
    plot(inputVector(:,1),inputVector(:,2),'-r');
else
    plot(0:1/sampleRate:(N-1)/sampleRate,inputVector,'-g');
end
plot(0:1/sampleRate:(N-1)/sampleRate,dataVec,'-b');
title('Input (time-domain) data');
xlabel('Time (s)'); ylabel('Value');
% legend({'Original'  'Filtered'},'interpreter','latex');
legend('Original' , 'Filtered');

% subplot(3,1,2);
% plot(freq,10*log10(psdx)); grid on;
% title('Periodogram (PSD) Using FFT');
% xlabel('Frequency (Hz)'); ylabel('Power/Frequency (dB/Hz)');

ax2 = subplot(2,1,2);
plot(freq2,xdftmag); grid on;
title('Magnitude Using FFT  ($|x(\omega j)|$)');
xlabel('Frequency (Hz)'); ylabel('Magnitude ($|x(\omega j)|$)');
xlim([0 sampleRate/2]);
%note only plotting the first half since the rest is a reflection


%============================
%Peak frequency
%============================
%Find the peak magnitude
xdftmag(1:round(N/2)) = 0;
[~, ii] = max(xdftmag);
peakFrequency = freq2(ii);
figure(h1);
axes(ax2); hold on;
plot(freq2(ii),xdftmag(ii),'or');

end

