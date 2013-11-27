close all;
clear all;

%=============================================
%Create system model
%=============================================

%First create a double integral system with the appropreate parameters
delayHd = 0.0959+0.14;
delayHd = 0.24;
lagTc   = 7.8382;
gainKc  = 6.7778;
rateTs  = 0.1;   %10Hz
doubeIntSystems = createdoubleint(delayHd,rateTs,lagTc,0,gainKc);

%The subsystem discSSLagDelay is the full augmented state space model.
AA = doubeIntSystems.discSSLagDelay.a;
BB = doubeIntSystems.discSSLagDelay.b;
CC = doubeIntSystems.discSSLagDelay.c;
DD = doubeIntSystems.discSSLagDelay.d;

%The complete double intergral system (inc delay) is,
ssnew = ss(AA,BB,CC,DD,rateTs);


%Check it against a ct simulation
tfnew = tf(1,[1 0 0],'inputdelay',delayHd)*tf(gainKc,[1/lagTc 1]);
figure;step(ssnew,5);hold on;step(tfnew,5);
tfnew = tf(1,[1 0 0])*tf(gainKc,[1/lagTc 1]);

%Extract the zero-delay B martix
sstemp = c2d(ss(tfnew),rateTs);
BBnoise = zeros(kl(ssnew.a),1);
BBnoise(1:3) = sstemp.b;

%=============================================
%Cost and noise (tuning matrices)
%=============================================
%Noise standard distributions
inputNoise = 0.1;
measuNoise = sqrt(0.0055);
QE = BBnoise*inputNoise*inputNoise*BBnoise';
RE = measuNoise*measuNoise;

%State and input weightings (accel, velocity, and position) 1/maxdev^2
QR = zeros(kl(ssnew.a),kl(ssnew.a));
QR(1,1) = 1/(0.1^2);
QR(2,2) = 1/(1.0^2);
QR(3,3) = 1/(0.05^2);
RR = 1/(0.37^2);

QXU = blkdiag(QR,RR);
QWV = blkdiag(QE,RE);

reg1 = lqg(ssnew,QXU,QWV);



%=============================================
%Create h2 system
%=============================================
h2AA = AA;
h2BB = cat(2,BBnoise*inputNoise,zeros(kl(ssnew.a),1));
h2BB = cat(2,h2BB,BB);
h2CC = cat(1,zeros(1,kl(ssnew.a)),sqrt(QR));
h2CC = cat(1,h2CC,CC);
h2DD = zeros(kl(h2CC),kw(h2BB));
h2DD(1,3) = sqrt(RR);
h2DD(end,2) = measuNoise;

ssh2 = ss(h2AA,h2BB,h2CC,h2DD,rateTs);
[reg2,CL,GAM,INFO]=h2syn(ssh2,1,1);


%=============================================
%Test closed loop step response
%=============================================
closedLoop1 = feedback(series(reg1,1.2*ssnew),-1);
closedLoop2 = feedback(series(reg2,1.2*ssnew),-1);


figure;step(closedLoop1,'-k');
hold on;

% step(closedLoop2,'-og');
% legend('LQG','H2');



