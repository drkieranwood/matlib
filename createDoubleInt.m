function [ doubleInt_OT ] = createDoubleInt( hd_IN , ts_IN , tf_IN , plot_IN , kc_IN )
%CreateDoubleInt A function to create double intergrator systems
%   This function creates several different realisations of a double
%   intergrator system and stores them in a structure. Care has been taken
%   to ensure the states within the state-space representations are
%   directly [acceleration, velocity, position] when appropreate.
%   1)  Continuous (non-delayed) transfer function
%   2)  Continuous delayed transfer function
%   3)  Continuous (non-delayed) state-space matrices (position output)
%   4)  Continuous (non-delayed) lagged transfer function
%   5)  Continuous delayed lagged transfer function
%   6)  Continuous (non-delayed) lagged state-space matrices (position output)
%
%   7)  Discrete (non-delayed) state-space
%   8)  Component matrices - Discrete delayed state space
%   9)  *Discrete delayed state-space (position output)
%   10)  Discrete (non-delayed) lagged state-space
%   11)  Component matrices - Discrete delayed lagged state space
%   12) *Discrete delayed lagged state-space (position output)
%
%   * indicates important systems. The pure delayed double integrator and
%   the lagged delayed double integrator in discrete state-space form.
%
%   hd_IN - the input delay
%   ts_IN - the discrete sample period
%   tf_IN - the lag first order bandwidth
%   plot_IN - flag to plot comparisons of the double intergrators

if hd_IN<0.0
    hd_IN = 0.0;
    warning('Delay < 0. Set to zero.');
end
if nargin < 3
    tf_IN = 0.01;
    plot_IN = 0;
end
if nargin < 4
    plot_IN = 0;
end
if nargin < 5
    kc_IN = 1;
end

plot_cont_on = 1;
plot_disc_on = 1;

% 0) Create the structure to hold the output
doubleInt_OT = struct('contTf',[]);

%Continuous
%============================================================

% 1) Continuous (non-delayed) transfer function
% correct 2013-09-06
doubleInt_OT.contTf = tf([kc_IN],[1 0 0]);

% 2) Continuous delayed transfer function
% correct 2013-09-06
doubleInt_OT.contTfDelay = tf([kc_IN],[1 0 0],'inputdelay',hd_IN);

% 3) Continuous (non-delayed) state-space matrices
% correct 2013-09-06
doubleInt_OT.contSS = ss([0 0;1 0],[kc_IN;0],[0 1],[0]);

% 4) Continuous (non-delayed) lagged transfer function
% correct 2013-09-06
doubleInt_OT.contTfLag = series( tf([kc_IN],[1/tf_IN 1]) , tf([1],[1 0 0]) );

% 5) Continuous delayed lagged transfer function
% correct 2013-09-06
doubleInt_OT.contTfLagDelay = series( tf([kc_IN],[1/tf_IN 1],'inputdelay',hd_IN) , tf([1],[1 0 0]) );

% 6) Continuous (non-delayed) lagged state-space matrices
% correct 2013-09-06
doubleInt_OT.contSSLag = ss([-tf_IN 0 0;1 0 0;0 1 0],[kc_IN*tf_IN;0;0],[0 0 1],[0]);


%Discrete
%============================================================
% 7) Discrete (non-delayed) state-space
% correct 2013-09-06
doubleInt_OT.discSS = ss([1 0;ts_IN 1],kc_IN*[ts_IN ; ts_IN*ts_IN*0.5],[0 1],[0],ts_IN);

% 8) Discrete delayed state-space (position output)

%Find the number of delay states to be added
g_temp = hd_IN;
n_temp = 0;
while (g_temp>ts_IN)
    n_temp = n_temp+1;
    g_temp = hd_IN-(n_temp*ts_IN);
end

%Create the components of the delayed matrices
A_temp = [ 1 0 ; ts_IN 1 ];
B1_temp = kc_IN*[ g_temp ; ((ts_IN*g_temp)-(g_temp*g_temp*0.5)) ];
B2_temp = kc_IN*[ (ts_IN-g_temp) ; ((ts_IN-g_temp)*(ts_IN-g_temp)*0.5) ];
C_temp = [ 0 1 ];
D_temp = [ 0 ];

%HACK: Save the component matrices
doubleInt_OT.discSSComp.AD = A_temp;
doubleInt_OT.discSSComp.BD1 = B1_temp;
doubleInt_OT.discSSComp.BD2 = B2_temp;
doubleInt_OT.discSSComp.CD = C_temp;


%If no extra states
if (n_temp < 1)
    clear AD BD CD DD;
    AD = [ A_temp B1_temp ; 0 0 0 ];
    BD = kc_IN*[ B2_temp ; 1 ];
    CD = [ C_temp 0 ];
    DD = [ 0 ];
end

%If extra delay states
if (n_temp >=1)
    clear AD BD CD DD;
    AD = zeros(n_temp+3);
    AD(1:2,1:2) = A_temp;
    AD(1:2,3) = B1_temp;
    AD(1:2,4) = B2_temp;
    temp = eye(n_temp);
    AD(3:3+(n_temp-1),4:4+(n_temp-1)) = temp;
    BD = zeros(n_temp+3,1);
    BD(end) = 1;
    CD = zeros(1,n_temp+3);
    CD(1:2) = C_temp;
    DD = [ 0 ];    
end

%Create the state space system
doubleInt_OT.discSSDelay = ss(AD,BD,CD,DD,ts_IN);


% 9) Discrete (non-delayed) lagged state-space
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
A_temp = [exp(-tf_IN*ts_IN) 0 0;(1/tf_IN)*(1-exp(-tf_IN*ts_IN)) 1 0;V_temp ts_IN 1];
B_temp = kc_IN*[1-exp(-tf_IN*ts_IN) ; tf_IN*V_temp ; tf_IN*W_temp];
C_temp = [0 0 1];
D_temp = [0];
doubleInt_OT.discSSLag = ss(A_temp,B_temp,C_temp,D_temp,ts_IN);

% 10) Discrete delayed lagged state-space (position output)
% NOTE this uses the previous representations algorithm with slightly
% adjusted values for ts_IN to be based on g_temp

%Find the number of delay states to be added
g_temp = hd_IN;
n_temp = 0;
while (g_temp>ts_IN)
    n_temp = n_temp+1;
    g_temp = hd_IN-(n_temp*ts_IN);
end
td_save = ts_IN;

%Create the components
%A
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
A_temp = [exp(-tf_IN*ts_IN) 0 0;(1/tf_IN)*(1-exp(-tf_IN*ts_IN)) 1 0;V_temp ts_IN 1];

%B1 (need A based on (td - g) and B based on (g))
ts_IN = td_save - g_temp;
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
A_temp1 = [exp(-tf_IN*ts_IN) 0 0;(1/tf_IN)*(1-exp(-tf_IN*ts_IN)) 1 0;V_temp ts_IN 1];

ts_IN = g_temp;
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
B_temp1 = kc_IN*[1-exp(-tf_IN*ts_IN) ; tf_IN*V_temp ; tf_IN*W_temp];
B1_temp = A_temp1*B_temp1;

%B2 (need B based on (td - g))
ts_IN = td_save - g_temp;
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
B2_temp = kc_IN*[1-exp(-tf_IN*ts_IN) ; tf_IN*V_temp ; tf_IN*W_temp];

%C and D are unchanged
C_temp = [0 0 1];
D_temp = [0];

%HACK: Save the component matrices
doubleInt_OT.discSSCompLag.AD = A_temp;
doubleInt_OT.discSSCompLag.BD1 = B1_temp;
doubleInt_OT.discSSCompLag.BD2 = B2_temp;
doubleInt_OT.discSSCompLag.CD = C_temp;

%If no extra states
if (n_temp < 1)
    clear AD BD CD DD;
    AD = [ A_temp B1_temp ; 0 0 0 0];
    BD = [ B2_temp ; 1 ];
    CD = [ C_temp 0 ];
    DD = [ 0 ];
end

%If extra delay states
if (n_temp >=1)
    clear AD BD CD DD;
    AD = zeros(n_temp+4);
    AD(1:3,1:3) = A_temp;
    AD(1:3,4) = B1_temp;
    AD(1:3,5) = B2_temp;
    temp = eye(n_temp);
    AD(4:4+(n_temp-1),5:5+(n_temp-1)) = temp;
    BD = zeros(n_temp+4,1);
    BD(end) = 1;
    CD = zeros(1,n_temp+4);
    CD(1:3) = C_temp;
    DD = [ 0 ];    
end

ts_IN = td_save;

doubleInt_OT.discSSLagDelay = ss(AD,BD,CD,DD,ts_IN);
%============================================================

%Plot the position comparisons to check the equivelence of the representations
if plot_IN
    figure('name','pos.');hold on;
    %Choose the timmings for the continuous simulation
    TT_temp = [0:0.01:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    %1)
    YY_temp = lsim(doubleInt_OT.contTf,UU_temp,TT_temp);
    if plot_cont_on 
        plot(TT_temp,YY_temp,'-r');
    end
    
    %2)
    YY_temp = lsim(doubleInt_OT.contTfDelay,UU_temp,TT_temp);
    if plot_cont_on
        plot(TT_temp-hd_IN,YY_temp,'-b');
    end
    
    %3)
    YY_temp = lsim(doubleInt_OT.contSS,UU_temp,TT_temp);
    if plot_cont_on
        plot(TT_temp,YY_temp,'-g');
    end
    
    %4)
    YY_temp = lsim(doubleInt_OT.contTfLag,UU_temp,TT_temp);
    if plot_cont_on
        plot(TT_temp,YY_temp,'-r');
    end
    
    %5)
    YY_temp = lsim(doubleInt_OT.contTfLagDelay,UU_temp,TT_temp);
    if plot_cont_on
        plot(TT_temp-hd_IN,YY_temp,'-b');
    end
    
    %6)
    YY_temp = lsim(doubleInt_OT.contSSLag,UU_temp,TT_temp);
    if plot_cont_on
        plot(TT_temp,YY_temp,'-g');
    end
    
    %Choose the timmings for the discrete simulation
    TT_temp = [0:ts_IN:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    %7)
    YY_temp = lsim(doubleInt_OT.discSS,UU_temp,TT_temp);
    if plot_disc_on
        plot(TT_temp,YY_temp,'-^m');
    end
    
    %8)
    YY_temp = lsim(doubleInt_OT.discSSDelay,UU_temp,TT_temp);
    if plot_disc_on
        plot(TT_temp-hd_IN,YY_temp,'-vk');
    end
     
    %9)
    YY_temp = lsim(doubleInt_OT.discSSLag,UU_temp,TT_temp);
    if plot_disc_on
        plot(TT_temp,YY_temp,'-^m');
    end
    
    %10)
    YY_temp = lsim(doubleInt_OT.discSSLagDelay,UU_temp,TT_temp);
    if plot_disc_on
        plot(TT_temp-hd_IN,YY_temp,'-vk'); 
    end
    
    legend('1contTf','2contTfDelay','3contSS','4contTfLag','5contTfLagDelay','6contSSLag','7discSS','8discSSDelay','9discSSLag','10discSSLagDelay','location','nw');
end

%Plot the position acceleration and velocity comparisons to check the equivelence of the
%representations
if plot_IN
    figure('name','vel.');hold on;
    %Choose the timmings for the continuous simulation
    TT_temp = [0:0.01:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    %The state space representations are 3,6,7,8,9,10 and can be converted
    %to output the velocity and acceleration when needed
    
    %Plot the gradient of the continuous functions for comparison
    %1)
    YY_temp = lsim(doubleInt_OT.contTf,UU_temp,TT_temp);
    if plot_cont_on 
        plot(TT_temp,gradient(YY_temp,0.01),'-k');
    end
    
    %2)
    YY_temp = lsim(doubleInt_OT.contTfDelay,UU_temp,TT_temp);
    if plot_cont_on 
        plot(TT_temp-hd_IN,gradient(YY_temp,0.01),'-k');
    end
    
    %4)
    YY_temp = lsim(doubleInt_OT.contTfLag,UU_temp,TT_temp);
    if plot_cont_on 
        plot(TT_temp,gradient(YY_temp,0.01),'-k');
    end
    
    %3) Plot the continuous SS (non-delayed non-lagged)
    A_temp = doubleInt_OT.contSS.a;
    B_temp = doubleInt_OT.contSS.b;
    C_temp = doubleInt_OT.contSS.c;
    D_temp = doubleInt_OT.contSS.d;
    YY_temp = lsim( ss( A_temp,B_temp,eye(length(A_temp)),zeros(length(A_temp),1) ) ,UU_temp,TT_temp);
    if plot_cont_on 
        plot(TT_temp,YY_temp(:,1),'-r');
    end
    
    %6) Plot the continuous SS lagged (non-delayed)
    A_temp = doubleInt_OT.contSSLag.a;
    B_temp = doubleInt_OT.contSSLag.b;
    C_temp = doubleInt_OT.contSSLag.c;
    D_temp = doubleInt_OT.contSSLag.d;
    YY_temp = lsim( ss( A_temp,B_temp,eye(length(A_temp)),zeros(length(A_temp),1) ) ,UU_temp,TT_temp);
    if plot_cont_on 
        plot(TT_temp,YY_temp(:,2),'-g');
    end
    
    
    %Choose the timmings for the discrete simulation
    TT_temp = [0:ts_IN:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    
    %7) Plot the discrete SS (non-delayed non-lagged)
    A_temp = doubleInt_OT.discSS.a;
    B_temp = doubleInt_OT.discSS.b;
    C_temp = doubleInt_OT.discSS.c;
    D_temp = doubleInt_OT.discSS.d;
    YY_temp = lsim( ss( A_temp,B_temp,eye(length(A_temp)),zeros(length(A_temp),1) ,ts_IN) ,UU_temp,TT_temp);
    if plot_disc_on 
        plot(TT_temp,YY_temp(:,1),'-ob');
    end
    
    %8) Plot the discrete SS delayed (non-lagged)
    A_temp = doubleInt_OT.discSSDelay.a;
    B_temp = doubleInt_OT.discSSDelay.b;
    C_temp = doubleInt_OT.discSSDelay.c;
    D_temp = doubleInt_OT.discSSDelay.d;
    YY_temp = lsim( ss( A_temp,B_temp,eye(length(A_temp)),zeros(length(A_temp),1) ,ts_IN) ,UU_temp,TT_temp);
    if plot_disc_on 
        plot(TT_temp-hd_IN,YY_temp(:,1),'-^r');
    end
    
    %9) Plot the discrete SS lagged (non-delayed)
    A_temp = doubleInt_OT.discSSLag.a;
    B_temp = doubleInt_OT.discSSLag.b;
    C_temp = doubleInt_OT.discSSLag.c;
    D_temp = doubleInt_OT.discSSLag.d;
    YY_temp = lsim( ss( A_temp,B_temp,eye(length(A_temp)),zeros(length(A_temp),1) ,ts_IN) ,UU_temp,TT_temp);
    if plot_disc_on 
        plot(TT_temp,YY_temp(:,2),'-vg');
    end
    
    %10) Plot the discrete SS lagged delayed
    A_temp = doubleInt_OT.discSSLagDelay.a;
    B_temp = doubleInt_OT.discSSLagDelay.b;
    C_temp = doubleInt_OT.discSSLagDelay.c;
    D_temp = doubleInt_OT.discSSLagDelay.d;
    YY_temp = lsim( ss( A_temp,B_temp,eye(length(A_temp)),zeros(length(A_temp),1) ,ts_IN) ,UU_temp,TT_temp);
    if plot_disc_on 
        plot(TT_temp-hd_IN,YY_temp(:,2),'-ob');
    end
    
    legend('1contTf(grad)','2contTfDelay(grad)','4contTfLag(grad)','3contSS','6contSSLag','7discSS','8discSSDelay','9discSSLag','10discSSLagDelay','location','nw');
    
    
    figure('name','accel.');hold on;
    %Choose the timmings for the continuous simulation
    TT_temp = [0:0.01:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    %5)
    YY_temp = lsim(doubleInt_OT.contTfLagDelay,UU_temp,TT_temp);
    if plot_cont_on 
        plot(TT_temp-hd_IN,gradient(gradient(YY_temp,0.01),0.01),'-k');
    end

    %6) Plot the continuous SS lagged (non-delayed)
    A_temp = doubleInt_OT.contSSLag.a;
    B_temp = doubleInt_OT.contSSLag.b;
    C_temp = doubleInt_OT.contSSLag.c;
    D_temp = doubleInt_OT.contSSLag.d;
    YY_temp = lsim( ss( A_temp,B_temp,eye(length(A_temp)),zeros(length(A_temp),1) ) ,UU_temp,TT_temp);
    if plot_disc_on 
        plot(TT_temp,YY_temp(:,1),'-r');
    end
    
    %Choose the timmings for the discrete simulation
    TT_temp = [0:ts_IN:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    %9) Plot the discrete SS lagged (non-delayed)
    A_temp = doubleInt_OT.discSSLag.a;
    B_temp = doubleInt_OT.discSSLag.b;
    C_temp = doubleInt_OT.discSSLag.c;
    D_temp = doubleInt_OT.discSSLag.d;
    YY_temp = lsim( ss( A_temp,B_temp,eye(length(A_temp)),zeros(length(A_temp),1) ,ts_IN) ,UU_temp,TT_temp);
    if plot_disc_on 
        plot(TT_temp,YY_temp(:,1),'-vg');
    end
    
    %10) Plot the discrete SS lagged delayed
    A_temp = doubleInt_OT.discSSLagDelay.a;
    B_temp = doubleInt_OT.discSSLagDelay.b;
    C_temp = doubleInt_OT.discSSLagDelay.c;
    D_temp = doubleInt_OT.discSSLagDelay.d;
    YY_temp = lsim( ss( A_temp,B_temp,eye(length(A_temp)),zeros(length(A_temp),1) ,ts_IN) ,UU_temp,TT_temp);
    if plot_disc_on 
        plot(TT_temp-hd_IN,YY_temp(:,1),'-ob');
    end
    
    legend('5contTfLagDelay(gradgrad)','6contSSLag','9discSSLag','10discSSLagDelay','location','nw');
end


end

