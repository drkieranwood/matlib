function [ filename ] = saveimage( fh , name , XX, YY, overwrite, pdfon)
%SAVEIMAGE Save a .PNG or .PDF image of the specified figure.
%   This function saves a .PNG image of the specified figure. The size of
%   the image in pixels is also specified as width and height. The pixel
%   size may be wrong by a few pixels due to some rounding.
%
%   This function is useful because the .EPS output from Matlab figures
%   do not always display properly and so using a raster image directly
%   from MATLAB is better. If using pdflatex then .PDF images can be used
%   in place of vector graphics. Use the pdfon flag.
%
%   USEAGE:
%   filename = saveImage(fh,'name',XX,YY,overwite,pdfon)
%
%   fh        - the matlab figure handle of the image to be saved
%   name      - the file name for the image (it will be saved in the current directory)
%   XX        - the width in pixels (150 - 9100)
%   YY        - the height in pixels (150 - 9100)
%   filename  - the saved image filename
%   overwrite - to ignore the overwite file warning
%   pdfon     - if set to 1 then output in pdf
%
%   Below 150px the axes and plots might not render correctly, above 9100px
%   and the MATLAB save command returns an error.
%
%   For a full width LaTeX document set the width to 1800px to have
%   approximately 10pt size text when the inage is embedded. The height can
%   be anything but the golden ratio gives a height of 1112px.

%Select the specified figure to be in focus.
figure(fh);


%===================
%Convert fonts
%===================

%Convert axes to use nice Latex markings. If subplots are detected then
%loop through them all.
axesHandles = findall(fh,'type','axes');
disp(axesHandles);
if (length(axesHandles) > 1)
    for ax = axesHandles(1:end)'
      subplot(ax);
%       set(gca,'FontName','cmr10');
      set(ax,'FontName','Times New Roman');
    end
else 
    axes(axesHandles);
%     set(gca,'FontName','cmr10');
    set(axesHandles,'FontName','Times New Roman');
end

%Make legends and other text into latex
set(findall(fh,'type','text'),'interpreter','latex');



%===================
%Remove white space (work in progress)
%===================
if 1
    %Get all children of the plot
    childs  = get(fh,'Children');
    nchilds = length(childs);
    %Get all bounds of the children
    wrapBounds=zeros(nchilds+1,4);
    wrapBounds(end,1:2)=inf;
    wrapBounds(end,3:4)=-inf;
    figBounds=zeros(nchilds+1,4);
    figBounds(end,1:2)=inf;
    figBounds(end,3:4)=-inf;
    h1 = figure;hold on;
    for ii=1:nchilds
        set(childs(ii),'Unit','normalized');
        pos=get(childs(ii),'Position');      %The tight wrap around the axes (i.e the coner of the actual plot)
        inset=get(childs(ii),'TightInset');  %The wrap around the axes, ticks and labels
        outer=get(childs(ii),'OuterPosition');
        %This is the box as a [left,bottom,right,top] set of coordinates that
        %bounds the axes,labels,ticks,and titles.
        wrapBounds(ii,:)=[pos(1)-inset(1) pos(2)-inset(2) pos(1)+pos(3)+inset(3) pos(2)+pos(4)+inset(4)];
        figBounds(ii,:) =[outer(1) outer(2) outer(1)+outer(3) outer(2)+outer(4)];
        if ii==1
            plot([pos(1) pos(1)+pos(3)],[pos(2) pos(2)+pos(4)],'-xr');
            plot([outer(1) outer(1)+outer(3)],[outer(2) outer(2)+outer(4)],'-sr');
            plot([pos(1)-inset(1) pos(1)+pos(3)+inset(3)],[pos(2)-inset(2) pos(2)+pos(4)+inset(4)],'-or');
        elseif ii==2
            plot([pos(1) pos(1)+pos(3)],[pos(2) pos(2)+pos(4)],'-xg');
            plot([outer(1) outer(1)+outer(3)],[outer(2) outer(2)+outer(4)],'-sg');
            plot([pos(1)-inset(1) pos(1)+pos(3)+inset(3)],[pos(2)-inset(2) pos(2)+pos(4)+inset(4)],'-og');
        elseif ii==3
            plot([pos(1) pos(1)+pos(3)],[pos(2) pos(2)+pos(4)],'-xb');
            plot([outer(1) outer(1)+outer(3)],[outer(2) outer(2)+outer(4)],'-sb');
            plot([pos(1)-inset(1) pos(1)+pos(3)+inset(3)],[pos(2)-inset(2) pos(2)+pos(4)+inset(4)],'-ob');
        end
        xlim([-0.1 1.1]);
        ylim([-0.1 1.1]);
    end

    %Find the minimum and maximum corners. These are the corners that 
    %envelop all of the figures children. 
    auxmin=min(wrapBounds(:,1:2));
    auxmax=max(wrapBounds(:,3:4));
    
    %Find the positions that Matlab thinks are the figure window edges
    %(these might be negative)
    figmin=min(figBounds(:,1:2));
    figmax=max(figBounds(:,3:4));
    
    figure(h1);
    plot([auxmin(1) auxmax(1)],[auxmin(2) auxmax(2)],'-*m');
    plot([figmin(1) figmax(1)],[figmin(2) figmax(2)],'--*m');
    %The figure window is expressed in the range 0:1 when using normalized
    %untis. Hence the off-set proportaions can be calculated now.
end

%===================
%Check Arguments
%===================

%If the image size is not specified then use 1800x1112px (size 10pt text when
%output pdf is embedded in a one column LaTeX document).
if nargin < 3
    XX = 1800;
    YY = 1112;
end
if nargin < 4
    YY = 1800;
end

%If the overwrite is not specified then do NOT overwrite
if nargin < 5
    overwrite = 0;
end

%If the pdf is not specified then output pdf
if nargin < 6
    pdfon = 1;
end


%===================
%Setup page size
%===================

%300dpi is the default resoloution and is good enough for most
%purposes. The dpi will not affect the number of pixels in the final image but
%may affect how the image is interpreted by other programs.

%Set the page size to be exactly the correct size to be 300dpi. Place the
%figure in the bottom corner and make it fill the page.
if pdfon
    dpi = 300;
else
    dpi = 300;
end
%Create pages size. This is the position on the page. Does not change
%screen appearance.
pagesize = [XX/dpi YY/dpi];
pagePosSize = [-((auxmin(1)-figmin(1))*pagesize(1)) -((auxmin(2)-figmin(2))*pagesize(2)) (((figmax(1)-auxmax(1))+(auxmin(1)-figmin(1)))*pagesize(1))+pagesize(1) (((figmax(2)-auxmax(2))+(auxmin(2)-figmin(2)))*pagesize(2))+pagesize(2)];
set(fh,'PaperUnits','inches','PaperPositionMode','manual','PaperSize',pagesize,'PaperPosition',pagePosSize,'Units','inches');


%===================
%Save the pdf or png
%===================

%Set the filename extension depending on if a png or pdf is required
if pdfon
        exttt = '.pdf';
        filename = strcat(name, exttt);
else
        exttt = '.png';
        filename = strcat(name, exttt);
end

%Check if the file already exists and if it should be overwritten.
if(~overwrite)
    while exist(filename,'file')
        disp('WARNING - File already exists!');
        resp = input('Overwrite? - 1(yes), 2(No) : ');
        if(resp == 1)
            break;
        else
            name = input('New file name? : ');
            filename = strcat(name, exttt);
        end
    end
end

%Print the figure to file
if pdfon
    print(fh, '-dpdf', '-r300' ,'-painters', filename);
else
    print(fh,'-dpng','-r300',filename);
end

end

