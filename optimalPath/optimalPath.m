%Script to test the possibility of using the image overlap to optimise a 
%MAV flight path in-order to maintain tracking quality.

close all;
clear all;
clc;


%======================
%Output set-up
%======================
%Set up the size of the virtual arena
arenaXLength = 15;
arenaYLength = 5;
%Figure for the output animation and path
h1 = figure('name','Optimal Path');
%Set the simulation playback speed (Hz)
outputPlaybackSpeed = 5;

%Colours
colour_mav  = 'k';
colour_mavpath  = '--ok';
colour_wall = 'k';
colour_viewlines = '--y';
colour_features_visible = 'r';
colour_features_overlap = 'g';
colour_features_notvis = 'b';


%======================
%Optimisation parameters
%======================
%The minimum number of features present in both images for a sucessful
%movement
minimumFeatureOverlap = 10;
%The 'camera' framerate (Hz)
global cameraFramerRate;
cameraFramerRate = 5;
%The maximum and minimum input values allowed.
minmaxInputs = 0.37;
%The ending position radius (m)
global maxEndRadius;
maxEndRadius = 0.01;
%The start and end position [x y]
global startPosition;
startPosition = [0.0 0.0];
global endPosition;
endPosition = [15.0 10.0];
%The number of separate inputs to the system
global inputCount;
inputCount = 6;


%======================
%Optimisation state
%======================
%The optimisation state is the input that is altered in-order to find the
%minimum cost. It cold be the entire set of inputs to a MAV simulation or
%just a few waypoints with lerp'd position assumed between them.

%The state is a series of inputs which will be applied at predefined times
%during the flight. A total of 20 inputs will be permitted to start, move,
%and stop the MAV.


%The constraints are min/max values on the camera location (this stops the
%solution diverging outside the arena), the final position appears in both
%the cost and as a constraint such that the MAV must end within a defined
%radius. Also maximum and minimum input values.
options = optimset('algorithm','sqp','display','iter');
constA = ones(inputCount+inputCount,1); %For positive upper bound limitation
constA = diag(constA);
constA = vertcat(constA,-constA);       %Put an negative version in for lower bound
constB = minmaxInputs*ones(inputCount+inputCount+inputCount+inputCount,1);
optimState = 0.0*ones(inputCount+inputCount,1);
optimState(1) = 0.0;        %Initial X input
optimState(2) = 0.0;        %Initial Y input
optimState = fmincon(@pathSimulation,optimState,constA,constB,[],[],[],[],[],options);


%======================
%Plot output
%======================
global XXout;
global YYout;
global TTout;
figure(h1);
plot(XXout(3,:),YYout(3,:),colour_mavpath);
xlim([-1 arenaXLength+1]);
ylim([-1 arenaYLength+1]);
hold on;
plot(startPosition(1),startPosition(2),'xg');
plot(endPosition(1),endPosition(2),'or');

figure('name','XY Pos');
ax1=subplot(3,1,1);
plot(TTout,XXout(3,:));
xlabel('Time (s)');
ylabel('X Pos (m)');
ylim([-1 arenaXLength+1]);
ax2=subplot(3,1,2);
plot(TTout,YYout(3,:));
xlabel('Time (s)');
ylabel('Y Pos (m)');
ylim([-1 arenaYLength+1]);
ax3=subplot(3,1,3);
plot(optimState(1:2:end),'-r');hold on;
plot(optimState(2:2:end),'-g');hold on;
xlabel('Time (s)');
ylabel('Inputs');
legend('X','Y');
linkaxes([ax1 ax2 ax3],'x');
ylim([-minmaxInputs*1.05 minmaxInputs*1.05]);

