%Creater a rendering of a hyperbolic parabaloid using straight lines
%K Wood
%08-Mar-2012

close all;

h1=figure;
hold on;
axis([0 10 0 10 0 10]);
axis equal;
x_range = [0:0.1:10];

%Need two vecotrs of points
vec1=min(x_range)*ones(length(x_range),1)
vec2=max(x_range)*ones(length(x_range),1)
vec11 = [vec1 x_range' x_range']
vec22 = [vec2 x_range' (fliplr(x_range))']

ii=0;
for x=x_range
    ii=ii+1;
    plot3([vec11(ii,1) vec22(ii,1)],[vec11(ii,2) vec22(ii,2)],[vec11(ii,3) vec22(ii,3)] ,'-r','linewidth',0.5);
end

ii=0;
for x=x_range
    ii=ii+1;
    plot3([vec11(ii,2) vec22(ii,2)],[vec11(ii,1) vec22(ii,1)],[vec11(ii,3) vec22(ii,3)] ,'-r','linewidth',0.5);
end
view([1 0.2 0.4]);
axis off;

