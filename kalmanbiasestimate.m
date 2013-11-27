%This script simulates a lagged double integral response to a step input
%when a bias is continually corrupting the input with a constant.

%============================
% Setup
%============================
close all;
clear all;
clc;

biasState_on = 1;
simDuration = 30;
samplingTs = 0.1;
delay = 0.05;
lagTc = 8.1;
bias = -1;

dblIntSyss = createdoubleint(delay,samplingTs,lagTc,0,1);
simSys = dblIntSyss.discSSLagDelay;

%============================
% Add bias state to model
%============================
AD = simSys.a;
BD = simSys.b;
CD = simSys.c;
DD = simSys.d;


AD = [1 zeros(1,kw(AD));zeros(kl(AD),1) AD];
BD = [0;BD];    %Bias state not affected by input
CD = [0 CD];    %Bias state not measured

if biasState_on;
    AD(4,1) = 1;    %Bias added to acceleration state. If the MAV is constantly tilted then it will be constantly accelerating.
    CD(1,1) = 0;
else
    AD(4,1) = 0;
    CD(1,1) = 1;
end
simSys2 = ss(AD,BD,CD,DD,samplingTs);


%============================
% Create estimator
%============================
% Assume input noise on system and prediction noise are identical.
inpNoiseStd = 0.01;
measMaxMin = 0.05;
meaNoiseStd = measMaxMin/3;
Btemp = dblIntSyss.discSSLag.b;
Btemp = Btemp*inpNoiseStd*inpNoiseStd*Btemp';
QQ = blkdiag(0.00001,Btemp,0);    %The bias state doesn't expect to be noisy
RR = meaNoiseStd*meaNoiseStd;
Lc = dlqe(AD,eye(kl(AD)),CD,QQ,RR);


%============================
% Simulate the system to create the ground truth and measurements
%============================
TT=0:samplingTs:simDuration;
TT=TT';
%Create a square input
UU = zeros(1,length(TT));
UU(1:10) =   1.0;
UU(11:20) = -1.0;

UU(101:110) = 1.0;
UU(111:120) = -1.0;
%Corrupt with noise
UU = UU';
UV = UU+inpNoiseStd*randn(length(UU),1);
%Initial state (zeros except bias)
X0 = zeros(kl(AD),1);
if biasState_on;
    X0(1) = bias;
    measCorupt = 0;
else
    measCorupt = bias;
end
%Create ground truth
YY = lsim(simSys2,UV,TT,X0);
%Corrupt with noise
ZZ = YY + meaNoiseStd*randn(length(YY),1) + measCorupt;
h1 = figure('name','ground truth');
hold on;
plot(TT,YY,'-k');
plot(TT,ZZ,'xk');
xlim([0 simDuration]);
legend('Truth','Measurements');

%============================
% Simulate Kalman filter (steady state)
% ZZ is the measurement available
% Running current form. First predict state from previous then correct with
% measurement.
%============================
%All zero initial state estimate
Xhat(:,1) = zeros(length(AD),1);
Xbar(:,1) = zeros(length(AD),1);

for ii = 2:1:length(TT)
    %Predict this state
    Xbar(:,ii) = AD*Xhat(:,ii-1) + BD*UU(ii-1);
    
    %Correct the state with measurement
    Xhat(:,ii) = Xbar(:,ii) + Lc*(ZZ(ii) - CD*Xbar(:,ii));
end

figure(h1);
plot(TT,Xhat(4,:),'--b');
legend('Truth','Measurements','Estimate');

h2 = figure('name','bias');
plot(TT,Xhat(1,:),'-k');

