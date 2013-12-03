%A simple script to enlarge the size of all open figures to be 80% width
%and height of screen with 10% borders.

%Get the current screen size.
set(0,'Units','pixels')
scsz = get(0,'ScreenSize');

%Get all open figure handles.
figHandles = findobj('Type','figure');

%Set all figure sizes to occupy most of the screen.
for hd = figHandles
    set(hd,'position',[scsz(3)*0.1 scsz(4)*0.1 scsz(3)*0.8 scsz(4)*0.8])
end

%Clear up variables
clear figHandles scsz hd;

disp('Figures enlarged ... done');