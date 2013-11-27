function [ output_args ] = pathSimulation( input_args )
%Simulate the MAV flying a path from its start location using the inputs
%specified in the input. The inputs are changed at 1 per second but the
%actual simulation is run at the 'cameraFramerRate'. The output is the time
%taken to reach the end position.

%The end time is the time when the MAV passes into a circle of radius
%'maxEndRadius' around the end position. If this does not occur then the
%cost is the closest position to the end point.

%=======================
%Inputs and outputs
%=======================
%Imported global settings
inputsToSystem = input_args;
global cameraFramerRate;
global maxEndRadius;
global startPosition;
global endPosition;
global inputCount;

%Exported output values
global XXout;
global YYout;
global TTout;


%=======================
%Create double intergal system
%=======================
%Start a simulation at the specified frame rate using the input arguments.
%Each pair of inputs is the x-y input to the MAV at 1 second intervals.
dblIntSyss = createdoubleint(0.0,(1.0/cameraFramerRate),8.2451,0,4.4727);
simSys = dblIntSyss.discSSLagDelay;


%=======================
%Simulation states and time vector
%=======================
%The inputs are applied at 1 per second. Hence total simulation time is
%The number of inputs in seconds. First input applied at time 0.
TT = 0:(1.0/cameraFramerRate):inputCount;

%X and Y positions (the two are assumed to be independent SISO systems.
%The start state is zeros except the position which is set to
%startPosition.
XX(:,1) = zeros(length(simSys.a),1);
XX(3,1) = startPosition(1);
YY(:,1) = zeros(length(simSys.a),1);
YY(3,1) = startPosition(2);
TTout(1)=0.0;

%Initial inputs
inputNo = 1;
curInputX = inputsToSystem((inputNo*2)-1);
curInputY = inputsToSystem(inputNo*2);
lastChangeTime = 0.0;


%Move along the time vector using the inputs
for ii = 1:1:length(TT);
    %Get the current simulation time (initial is zero).
    curTime = TT(ii);
    
    %Check if the current state (ii) is at the end location.
    tempDiffX = XX(3,ii) - endPosition(1);
    tempDiffY = YY(3,ii) - endPosition(2);
    tempDist = norm([tempDiffX;tempDiffY]);
    if (tempDist < maxEndRadius)
        %If close to the end position then store the time and 
        %path, and return.
        output_args = TT(ii);
        XXout = XX;
        YYout = YY;
        TTout = TT(1:ii);
        disp('reached end');
        return;
    end
    
    %If then end has not been reached then continue the simulation
    %Find the current input.
    if (curTime>(lastChangeTime+1))
        inputNo = inputNo + 1;
        lastChangeTime = lastChangeTime+1;
    end
    curInputX = inputsToSystem((inputNo*2)-1);
    curInputY = inputsToSystem(inputNo*2);
    
    %Use the input to update the states. This predicts the 
    %next state (ii+1)
    XX(:,ii+1) = (simSys.a)*XX(:,ii) + (simSys.b)*curInputX;
    YY(:,ii+1) = (simSys.a)*YY(:,ii) + (simSys.b)*curInputY;
    TTout(ii+1) = TTout(ii)+(1.0/cameraFramerRate);
end

%If this position has been reached then the simulation did not pass near
%the end position. Hence look for the closest point of approach (magnified
%by 10 to ensure the time will always be lower cost).
tempMinDist = 1000;
for ii=1:1:length(XX(3,:))
    tempDiffX = XX(3,ii) - endPosition(1);
    tempDiffY = YY(3,ii) - endPosition(2);
    tempDist = norm([tempDiffX;tempDiffY]);
    if (tempDist<tempMinDist)
        tempMinDist = tempDist;
    end
end


%Set outputs
XXout = XX;
YYout = YY;
TTout;
output_args = tempMinDist*10;
return;

end

