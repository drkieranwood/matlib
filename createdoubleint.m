function [ doubleInt_OT ] = createdoubleint( hd_IN , ts_IN , tf_IN , plot_IN , kc_IN )
%createdoubleint A function to create double intergrator systems
%   This function creates several different realisations of a double
%   intergrator system and stores them in a structure. Care has been taken
%   to ensure the states within the state-space representations are
%   directly [acceleration, velocity, position] when appropreate.
%   1)  Continuous transfer function
%   2)  Continuous delayed transfer function
%   3)  Continuous state-space
%   4)  Continuous lagged transfer function
%   5)  Continuous delayed lagged transfer function
%   6)  Continuous lagged state-space 
%
%   7)  Discrete state-space
%   8)  ^Component matrices - Discrete delayed state space (Ad1,Bd1,Bd2,Cd1)
%   9)  *Discrete delayed state space
%   10) Discrete lagged state-space
%   11) ^Component matrices - Discrete delayed lagged state space (Ad1,Bd1,Bd2,Cd1)
%   12) *Discrete delayed lagged state-space
%
%   * indicates important systems. The pure delayed double integrator and
%   the lagged delayed double integrator in discrete state-space form.
%
%   ^ indicates component matrices that would be used to simulate the system if
%   the inputs were delayed externally, hence creating a two input system 
%   with the same number of states as a non-delayed system.
%   x+ = Ad1*x + Bd1*u(oldest) + Bd2*u(2ndoldest)
%   y  = Cd1*x
%
%   hd_IN - the input delay
%   ts_IN - the discrete sample period
%   tf_IN - the lag first order bandwidth is rad/s
%   plot_IN - flag to plot comparisons of the double intergrators
%   kc_IN - the open loop gain



%========================
%Check the inputs
%========================
%Check the delay
if nargin<1
    warning('DOUBLEINT:warn','Delay not set. Delay set to 0.1s.');
    hd_IN = 0.1;
end
if hd_IN<0.0
    error('DOUBLEINT:err','Delay < 0.0.');
end

%Check the sample period
if nargin<2
    warning('DOUBLEINT:warn','Sample period not set. Sample period set to 0.2s.');
    ts_IN = 0.2;
end
if ts_IN<0.0
    error('DOUBLEINT:warn','Sample period <= 0.0.');
end

%Check the lag time constant
if nargin<3
    warning('DOUBLEINT:warn','Lag TC not set. Lag TC set to 5rad/s.');
    tf_IN = 5;
end

%Check if the comparison plots are wanted
if nargin<4
    %Silently set to NOT plot examples
    plot_IN = 1;
end

%Check the open loop gain
if nargin<5
    %Silently set the gain to unity
    kc_IN = 1;
end

%Debug flags
plot_cont_on = 1;
plot_disc_on = 1;

% Create a structure to hold the output systems neatly.
doubleInt_OT = struct('contTf',[]);


%========================
%Create continuous systems
%========================

% 1) Continuous (non-delayed, non-lagged) transfer function
% correct 2013-09-16
doubleInt_OT.contTf = tf([kc_IN],[1 0 0]);

% 2) Continuous delayed (non-lagged) transfer function
% correct 2013-09-16
doubleInt_OT.contTfDelay = tf([kc_IN],[1 0 0],'inputdelay',hd_IN);

% 3) Continuous (non-delayed, non-lagged) state-space
% correct 2013-09-16
doubleInt_OT.contSS = ss([0 0;1 0],[kc_IN;0],[0 1],[0]);

% 4) Continuous lagged (non-delayed) transfer function
% correct 2013-09-16
doubleInt_OT.contTfLag = series( tf([kc_IN],[1/tf_IN 1]) , tf([1],[1 0 0]) );

% 5) Continuous delayed lagged transfer function
% correct 2013-09-16
doubleInt_OT.contTfLagDelay = series( tf([kc_IN],[1/tf_IN 1],'inputdelay',hd_IN) , tf([1],[1 0 0]) );

% 6) Continuous lagged (non-delayed) state-space
% correct 2013-09-16
doubleInt_OT.contSSLag = ss([-tf_IN 0 0;1 0 0;0 1 0],[kc_IN*tf_IN;0;0],[0 0 1],[0]);


%========================
%Create discrete systems
%========================

% 7) Discrete (non-delayed, non-lagged) state-space
% correct 2013-09-16
doubleInt_OT.discSS = ss([1 0;ts_IN 1],kc_IN*[ts_IN ; ts_IN*ts_IN*0.5],[0 1],[0],ts_IN);

% 8) Discrete delayed (non-lagged) state-space
% correct 2013-09-16

%Find the number of delay states to be added.
%hd_IN  - the total delay time
%g_temp - the partial time-setp delay
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

%Save the component matrices
doubleInt_OT.discSSComp.ad1 = A_temp;
doubleInt_OT.discSSComp.bd1 = B1_temp;
doubleInt_OT.discSSComp.bd2 = B2_temp;
doubleInt_OT.discSSComp.cd1 = C_temp;

%If n=0 then one extra state is added
if (n_temp < 1)
    clear AD BD CD DD;
    AD = [ A_temp B1_temp ; 0 0 0 ];
    BD = [ B2_temp ; 1 ];
    CD = [ C_temp 0 ];
    DD = [ 0 ];
end

%If n>0 then n+1 extra states added
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


% 9) Discrete lagged (non-delayed) state-space
% correct 2013-09-16
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
A_temp = [exp(-tf_IN*ts_IN) 0 0;(1/tf_IN)*(1-exp(-tf_IN*ts_IN)) 1 0;V_temp ts_IN 1];
B_temp = kc_IN*[1-exp(-tf_IN*ts_IN) ; tf_IN*V_temp ; tf_IN*W_temp];
C_temp = [0 0 1];
D_temp = [0];
doubleInt_OT.discSSLag = ss(A_temp,B_temp,C_temp,D_temp,ts_IN);


% 10) Discrete delayed lagged state-space
% correct 2013-09-16

% NOTE this uses the previous representations algorithms with slightly
% adjusted values for ts_IN to be based on (g_temp) and (ts_IN-g_temp)

%Find the number of delay states to be added
g_temp = hd_IN;
n_temp = 0;
while (g_temp>ts_IN)
    n_temp = n_temp+1;
    g_temp = hd_IN-(n_temp*ts_IN);
end
td_save = ts_IN;

%Create the components
%Ad1
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
A_temp = [exp(-tf_IN*ts_IN) 0 0;(1/tf_IN)*(1-exp(-tf_IN*ts_IN)) 1 0;V_temp ts_IN 1];

%Bd1 (need A based on (ts - g) and B based on (g))
ts_IN = td_save - g_temp;
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
A_temp1 = [exp(-tf_IN*ts_IN) 0 0;(1/tf_IN)*(1-exp(-tf_IN*ts_IN)) 1 0;V_temp ts_IN 1];

ts_IN = g_temp;
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
B_temp1 = kc_IN*[1-exp(-tf_IN*ts_IN) ; tf_IN*V_temp ; tf_IN*W_temp];
B1_temp = A_temp1*B_temp1;

%Bd2 (need B based on (ts - g))
ts_IN = td_save - g_temp;
V_temp = ((1/(tf_IN*tf_IN))*exp(-tf_IN*ts_IN)) + ((1/tf_IN)*ts_IN) - (1/(tf_IN*tf_IN));
W_temp = (1/(tf_IN*tf_IN*tf_IN)) - ((1/(tf_IN*tf_IN))*ts_IN) + ((1/tf_IN)*ts_IN*ts_IN*0.5) - ((1/(tf_IN*tf_IN*tf_IN))*exp(-tf_IN*ts_IN));
B2_temp = kc_IN*[1-exp(-tf_IN*ts_IN) ; tf_IN*V_temp ; tf_IN*W_temp];

%Cd1 and D are unchanged
C_temp = [0 0 1];
D_temp = [0];

%Save the component matrices
doubleInt_OT.discSSCompLag.ad1 = A_temp;
doubleInt_OT.discSSCompLag.bd1 = B1_temp;
doubleInt_OT.discSSCompLag.bd2 = B2_temp;
doubleInt_OT.discSSCompLag.cd1 = C_temp;

%If n=0 then one extra state is added
if (n_temp < 1)
    clear AD BD CD DD;
    AD = [ A_temp B1_temp ; 0 0 0 0];
    BD = [ B2_temp ; 1 ];
    CD = [ C_temp 0 ];
    DD = [ 0 ];
end

%If n>0 then n+1 extra states added
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


%========================
%Check equivelence
%========================
%Plot the position responses
if plot_IN
    figure('name','Pos.');hold on;
    xlabel('Time (s)');
    ylabel('Position');
    
    %Choose the timmings and input for the continuous simulations.
    TT_temp = [0:0.01:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    if plot_cont_on 
        %1) Cont. TF
        YY_temp = lsim(doubleInt_OT.contTf,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-r');

        %2) Cont. TF Delay
        YY_temp = lsim(doubleInt_OT.contTfDelay,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-g');

        %3) Cont. SS
        YY_temp = lsim(doubleInt_OT.contSS,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-b');
    
        %4) Cont. TF Lag
        YY_temp = lsim(doubleInt_OT.contTfLag,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-r');

        %5) Cont. TF Lag Delay
        YY_temp = lsim(doubleInt_OT.contTfLagDelay,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-g');

        %6) Cont. SS Lag
        YY_temp = lsim(doubleInt_OT.contSSLag,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-b');
    end
    
    %Choose the timmings for the discrete simulation
    TT_temp = [0:ts_IN:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    if plot_disc_on
        %7) Disc. SS
        YY_temp = lsim(doubleInt_OT.discSS,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-^m');
   
        %8) Disc. SS Delay
        YY_temp = lsim(doubleInt_OT.discSSDelay,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-vk');
     
        %9) Disc. Lag
        YY_temp = lsim(doubleInt_OT.discSSLag,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-om');
    
        %10) Disc. SS Lag Delay
        YY_temp = lsim(doubleInt_OT.discSSLagDelay,UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-+k'); 
    end
    
    legend('1:contTf','2:contTfDelay','3:contSS','4:contTfLag','5:contTfLagDelay','6:contSSLag','7:discSS','8:discSSDelay','9:discSSLag','10:discSSLagDelay','location','nw');
end

%Plot the velocity responses. The velcoity output of transfer functions is
%created by converting the double intergrator into a single intergrator.
if plot_IN
    figure('name','Vel.');hold on;
    xlabel('Time (s)');
    ylabel('Velocity');
    
    %Choose the timmings and input for the continuous simulations.
    TT_temp = [0:0.01:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
      
    if plot_cont_on 
        %1) Cont. TF
        YY_temp = lsim(series(tf([1 0],[1]),doubleInt_OT.contTf),UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-r');

        %2) Cont. TF Delay
        YY_temp = lsim(series(tf([1 0],[1]),doubleInt_OT.contTfDelay),UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-g');

        %3) Cont. SS
        YY_temp = lsim(ss(doubleInt_OT.contSS.a,doubleInt_OT.contSS.b,eye(length(doubleInt_OT.contSS.a)),zeros(length(doubleInt_OT.contSS.a),1)),UU_temp,TT_temp);
        plot(TT_temp,YY_temp(:,1),'-b');
    
        %4) Cont. TF Lag
        YY_temp = lsim(series(tf([1 0],[1]),doubleInt_OT.contTfLag),UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-r');

        %5) Cont. TF Lag Delay
        YY_temp = lsim(series(tf([1 0],[1]),doubleInt_OT.contTfLagDelay),UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-g');

        %6) Cont. SS Lag
        doubleInt_OT.contSSLag
        YY_temp = lsim(ss(doubleInt_OT.contSSLag.a,doubleInt_OT.contSSLag.b,eye(length(doubleInt_OT.contSSLag.a)),zeros(length(doubleInt_OT.contSSLag.a),1)),UU_temp,TT_temp);
        plot(TT_temp,YY_temp(:,2),'-b');
    end
    
    %Choose the timmings for the discrete simulation
    TT_temp = [0:ts_IN:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    if plot_disc_on
        %7) Disc. SS
        YY_temp = lsim(ss(doubleInt_OT.discSS.a,doubleInt_OT.discSS.b,eye(length(doubleInt_OT.discSS.a)),zeros(length(doubleInt_OT.discSS.a),1),ts_IN),UU_temp,TT_temp);
        plot(TT_temp,YY_temp(:,1),'-^m');
   
        %8) Disc. SS Delay
        YY_temp = lsim(ss(doubleInt_OT.discSSDelay.a,doubleInt_OT.discSSDelay.b,eye(length(doubleInt_OT.discSSDelay.a)),zeros(length(doubleInt_OT.discSSDelay.a),1),ts_IN),UU_temp,TT_temp);
        plot(TT_temp,YY_temp(:,1),'-vk');
     
        %9) Disc. Lag
        YY_temp = lsim(ss(doubleInt_OT.discSSLag.a,doubleInt_OT.discSSLag.b,eye(length(doubleInt_OT.discSSLag.a)),zeros(length(doubleInt_OT.discSSLag.a),1),ts_IN),UU_temp,TT_temp);
        plot(TT_temp,YY_temp(:,2),'-om');
    
        %10) Disc. SS Lag Delay
        YY_temp = lsim(ss(doubleInt_OT.discSSLagDelay.a,doubleInt_OT.discSSLagDelay.b,eye(length(doubleInt_OT.discSSLagDelay.a)),zeros(length(doubleInt_OT.discSSLagDelay.a),1),ts_IN),UU_temp,TT_temp);
        plot(TT_temp,YY_temp(:,2),'-+k'); 
    end
    
    legend('1:contTf','2:contTfDelay','3:contSS','4:contTfLag','5:contTfLagDelay','6:contSSLag','7:discSS','8:discSSDelay','9:discSSLag','10:discSSLagDelay','location','nw');
end

%Plot the acceleration responses
if plot_IN
    
    figure('name','Accel.');hold on;
    xlabel('Time (s)');
    ylabel('Acceleration');
    
    %Choose the timmings and input for the continuous simulations.
    TT_temp = [0:0.01:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    if plot_cont_on 
        %1) Cont. TF
        YY_temp = lsim(series(tf([1 0 0],[1]),doubleInt_OT.contTf),UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-r');

        %2) Cont. TF Delay
        YY_temp = lsim(series(tf([1 0 0],[1]),doubleInt_OT.contTfDelay),UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-g');

        %3) Cont. SS
        YY_temp = lsim(ss(doubleInt_OT.contSS.a,doubleInt_OT.contSS.b,eye(length(doubleInt_OT.contSS.a)),zeros(length(doubleInt_OT.contSS.a),1)),UU_temp,TT_temp);
        plot(TT_temp,gradient(YY_temp(:,1),0.01),'-b');
    
        %4) Cont. TF Lag
        YY_temp = lsim(series(tf([1 0 0],[1]),doubleInt_OT.contTfLag),UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-r');

        %5) Cont. TF Lag Delay
        YY_temp = lsim(series(tf([1 0 0],[1]),doubleInt_OT.contTfLagDelay),UU_temp,TT_temp);
        plot(TT_temp,YY_temp,'-g');

        %6) Cont. SS Lag
        doubleInt_OT.contSSLag
        YY_temp = lsim(ss(doubleInt_OT.contSSLag.a,doubleInt_OT.contSSLag.b,eye(length(doubleInt_OT.contSSLag.a)),zeros(length(doubleInt_OT.contSSLag.a),1)),UU_temp,TT_temp);
        plot(TT_temp,YY_temp(:,1),'-b');
    end
    
    %Choose the timmings for the discrete simulation
    TT_temp = [0:ts_IN:ts_IN*20]';
    UU_temp = ones(length(TT_temp),1);
    
    if plot_disc_on
        %7) Disc. SS
        YY_temp = lsim(ss(doubleInt_OT.discSS.a,doubleInt_OT.discSS.b,eye(length(doubleInt_OT.discSS.a)),zeros(length(doubleInt_OT.discSS.a),1),ts_IN),UU_temp,TT_temp);
        plot(TT_temp,gradient(YY_temp(:,1),ts_IN),'-^m');
   
        %8) Disc. SS Delay
        YY_temp = lsim(ss(doubleInt_OT.discSSDelay.a,doubleInt_OT.discSSDelay.b,eye(length(doubleInt_OT.discSSDelay.a)),zeros(length(doubleInt_OT.discSSDelay.a),1),ts_IN),UU_temp,TT_temp);
        plot(TT_temp,gradient(YY_temp(:,1),ts_IN),'-vk');
     
        %9) Disc. Lag
        YY_temp = lsim(ss(doubleInt_OT.discSSLag.a,doubleInt_OT.discSSLag.b,eye(length(doubleInt_OT.discSSLag.a)),zeros(length(doubleInt_OT.discSSLag.a),1),ts_IN),UU_temp,TT_temp);
        plot(TT_temp,YY_temp(:,1),'-om');
    
        %10) Disc. SS Lag Delay
        YY_temp = lsim(ss(doubleInt_OT.discSSLagDelay.a,doubleInt_OT.discSSLagDelay.b,eye(length(doubleInt_OT.discSSLagDelay.a)),zeros(length(doubleInt_OT.discSSLagDelay.a),1),ts_IN),UU_temp,TT_temp);
        plot(TT_temp,YY_temp(:,1),'-+k'); 
    end
    
    legend('1:contTf','2:contTfDelay','3:contSS(grad)','4:contTfLag','5:contTfLagDelay','6:contSSLag','7:discSS(grad)','8:discSSDelay(grad)','9:discSSLag','10:discSSLagDelay','location','se');
end


end

