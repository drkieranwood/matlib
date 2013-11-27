function [ filename ] = saveimage(fh,name,XX,YY,overwrite,pdfon,nudgeup)
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
%   nudgeup   - if the xlabel has a lot of latex that makes it spen two
%   lines then some extra space is needed. This is the number of pixels.
%
%   Below 150px the axes and plots might not render correctly, above 9100px
%   and the MATLAB save command returns an error.
%
%   For a full width LaTeX document set the width to 1800px to have
%   approximately 10pt size text when the inage is embedded. The height can
%   be anything but the golden ratio gives a height of 1112px.

%Example figures
%Single plot
% figure;plot(peaks);xlabel('Something$(x^{2})$');ylabel('sonething else$(log^{2}_{10})$');legend('1$(\theta^{2})$','2');

%Double plot
% figure;subplot(2,1,1);plot(peaks);xlabel('Something$(x^{2})$');ylabel('sonething else$(log^{2}_{10})$');legend('1$(\theta^{2})$','2');subplot(2,1,2);plot(peaks);xlabel('Something$(x^{2})$');ylabel('sonething else$(log^{2}_{10})$');

%Triple plot
% figure;subplot(3,1,1);plot(peaks);xlabel('$(x^{2})$');ylabel('$(log^{2}_{10})$');legend('1$(\theta^{2})$','2');subplot(3,1,2);plot(peaks);xlabel('$(x^{2})$');ylabel('$(log^{2}_{10})$');subplot(3,1,3);plot(peaks);xlabel('$(x^{2})$');ylabel('$(log^{2}_{10})$');

%Quad plot
% figure;subplot(2,2,1);plot(peaks);xlabel('Something$(x^{2})$');ylabel('sonething else$(log^{2}_{10})$');legend('1','2');subplot(2,2,2);plot(peaks);xlabel('Something$(x^{2})$');ylabel('sonething else$(log^{2}_{10})$');legend('1$(\theta^{2})$','2');subplot(2,2,3);plot(peaks);xlabel('Something$(x^{2})$');ylabel('sonething else$(log^{2}_{10})$');subplot(2,2,4);plot(peaks);xlabel('Something$(x^{2})$');ylabel('sonething else$(log^{2}_{10})$');

%Select the specified figure to be in focus.
figure(fh);
plot_on = 0;


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

%If the nudge up is not specified then do not
if nargin < 7
    nudgeup = 0;
end

%===================
%Set the resoloution of the output
%===================
%Set the dpi for the output.
if pdfon
    dpi = 300;
else
    dpi = 300;
end


%===================
%Resize screen position to be correct aspect
%===================
curPos = get(fh,'Position');
%Leave the width and change the height
newH = curPos(3)*(YY/XX);
set(fh,'Position',[curPos(1) curPos(2) curPos(3) newH]);


%===================
%Remove white space (work in progress)
%===================
if 1    
    %If to include an extra set of points at 0 and 1
    defaultMin = 0.5;
    defaultMax = 0.5;
    %Get all children of the plot
    childs  = get(fh,'Children');
    nchilds = length(childs);
    %Get all bounds of the children. Add an extra entry for when subplots
    %are used. 
    %wrapBounds(childHandle1,[left bottom right top])
    %           childHandle2,[left bottom right top]...
    %        ...extraBounds ,[0    0      1     1  ])
    wrapBounds=zeros(nchilds+1,4);
    wrapBounds(end,1:2)=defaultMin;
    wrapBounds(end,3:4)=defaultMax;
    %figBounds(childHandle1,[left bottom right top])
    %          childHandle2,[left bottom right top]...
    %       ...extraBounds ,[0    0      1     1  ])
    figBounds=zeros(nchilds+1,4);
    figBounds(end,1:2)=defaultMin;
    figBounds(end,3:4)=defaultMax;
    
    if plot_on
        h1 = figure;hold on;
    end
    for ii=1:nchilds
        %Cycle through the children and get (in normalised units) the,
        %   position          pos[left bottom width height]
        %   label margins   inset[left bottom right top]
        %   figure bounds   outer[left bottom width height]
        set(childs(ii),'units','normalized');
        pos=get(childs(ii),'Position');         %The tight wrap around the axes (i.e the actual plot area)
        inset=get(childs(ii),'TightInset');     %The margins added for including the axes labels and ticks
        outer=get(childs(ii),'OuterPosition');  %What matlab thinks is the bounding figure window
        set(childs(ii),'ActivePositionProperty','position');
     
        wrapBounds(ii,:)=[pos(1)-inset(1) pos(2)-inset(2) pos(1)+pos(3)+inset(3) pos(2)+pos(4)+inset(4)];
        figBounds(ii,:) =[outer(1) outer(2) outer(1)+outer(3) outer(2)+outer(4)];
         
        if plot_on
            plot(0.5,0.5,'-xr');
            plot(0.5,0.5,'-sr');
            plot(0.5,0.5,'-or');
            plot(0.5,0.5,'-*k');
            plot(0.5,0.5,'-^k');
            legend('axes pos','figure limits','axes+margins','aux limits','fig limits','location','nw');
            if ii==1
                plot([pos(1) pos(1)+pos(3)],[pos(2) pos(2)+pos(4)],'-xr');
                plot([figBounds(ii,1)  figBounds(ii,3)] ,[figBounds(ii,2)  figBounds(ii,4)] ,'-sr');
                plot([wrapBounds(ii,1) wrapBounds(ii,3)],[wrapBounds(ii,2) wrapBounds(ii,4)],'-or');
            elseif ii==2
                plot([pos(1) pos(1)+pos(3)],[pos(2) pos(2)+pos(4)],'-xg');
                plot([figBounds(ii,1)  figBounds(ii,3)] ,[figBounds(ii,2)  figBounds(ii,4)] ,'-sg');
                plot([wrapBounds(ii,1) wrapBounds(ii,3)],[wrapBounds(ii,2) wrapBounds(ii,4)],'-ob');
            elseif ii==3
                plot([pos(1) pos(1)+pos(3)],[pos(2) pos(2)+pos(4)],'-xb');
                plot([figBounds(ii,1)  figBounds(ii,3)] ,[figBounds(ii,2)  figBounds(ii,4)] ,'-sb');
                plot([wrapBounds(ii,1) wrapBounds(ii,3)],[wrapBounds(ii,2) wrapBounds(ii,4)],'-ob');
            elseif ii==4
                plot([pos(1) pos(1)+pos(3)],[pos(2) pos(2)+pos(4)],'-xm');
                plot([figBounds(ii,1)  figBounds(ii,3)] ,[figBounds(ii,2)  figBounds(ii,4)] ,'-sm');
                plot([wrapBounds(ii,1) wrapBounds(ii,3)],[wrapBounds(ii,2) wrapBounds(ii,4)],'-om');
            elseif ii==5
                plot([pos(1) pos(1)+pos(3)],[pos(2) pos(2)+pos(4)],'-xy');
                plot([figBounds(ii,1)  figBounds(ii,3)] ,[figBounds(ii,2)  figBounds(ii,4)] ,'-sy');
                plot([wrapBounds(ii,1) wrapBounds(ii,3)],[wrapBounds(ii,2) wrapBounds(ii,4)],'-oy');
            end
            xlim([-0.1 1.1]);
            ylim([-0.1 1.1]);
        end
    end

    %Find the minimum and maximum corners. These are the corners that 
    %envelop all of the figures children.
    wrapmin=[min(wrapBounds(:,1)) min(wrapBounds(:,2))];   %[left  bottom]
    wrapmax=[max(wrapBounds(:,3)) max(wrapBounds(:,4))];   %[right top   ]
    
    %Find the positions that Matlab thinks are the figure window edges
    %(these might be negative)
    figmin=[min(figBounds(:,1)) min(figBounds(:,2))];   %[left  bottom]
    figmax=[max(figBounds(:,3)) max(figBounds(:,4))];   %[right top   ]

    %The figure limits should always be (0:1)
    figmin(1) = 0;
    figmin(2) = 0;
    figmax(1) = 1;
    figmax(2) = 1;

    if plot_on
        figure(h1);
        plot([wrapmin(1) wrapmax(1)],[wrapmin(2) wrapmax(2)],'-*k');
        plot([figmin(1)  figmax(1)] ,[figmin(2)  figmax(2)] ,'-^k');
    end

    if plot_on
        %Add some axes to show these position on the real plot.
        figure(fh);
        axes('position',[figmin(1) figmin(2) figmax(1)-figmin(1) figmax(2)-figmin(2)],'nextplot','add','color',[0.0 0.8 0.0], 'YTick', [],'XTick', []);
        axes('position',[wrapmin(1) wrapmin(2) wrapmax(1)-wrapmin(1) wrapmax(2)-wrapmin(2)],'nextplot','add','color',[0.8 0.0 0.0], 'YTick', [],'XTick', []);
        axes('position',[0 0 0.01 0.01],'nextplot','add','color',[0.0 0.0 0.8], 'YTick', [],'XTick', []);
        axes('position',[0.99 0.99 0.01 0.01],'nextplot','add','color',[0.0 0.0 0.8], 'YTick', [],'XTick', []);

        %Move original plots back to top layer
        for ii=nchilds:-1:1
            uistack(childs(ii), 'top');
        end
    end
end


%===================
%Setup page size
%===================

%300dpi is the default resoloution and is good enough for most
%purposes. The dpi will not affect the number of pixels in the final image but
%may affect how the image is interpreted by other programs.

%Create pages size. This is the position on the page. Does not change
%screen appearance, only the output pdf.
pagesize = [XX/dpi YY/dpi];


%The position is comprosed of [left bottom width height]

%Left Bottom. This is the difference between figmin and auxmin multiplied
%by the page size. It is made negative to move the figure over to ocupy the
%extra blank space.
temp_left   = -(  (wrapmin(1)-figmin(1))*pagesize(1)  );
temp_bottom = -(  (wrapmin(2)-figmin(2))*pagesize(2)  );

%Width Height. The page needs to be the normal size plus the blank spaces
%multiplied by the page width.
temp_width  = pagesize(1) + pagesize(1)*( ( figmax(1)-wrapmax(1) )+( wrapmin(1)-figmin(1) ) );
temp_height = pagesize(2) + pagesize(2)*( ( figmax(2)-wrapmax(2) )+( wrapmin(2)-figmin(2) ) );

pagePosSize = [temp_left temp_bottom temp_width temp_height];

set(fh,'PaperUnits','inches');
set(fh,'PaperSize',pagesize+[0 nudgeup/dpi]);
set(fh,'PaperPositionMode','manual');
set(fh,'PaperPosition',pagePosSize+[0 nudgeup/dpi 0 0]);



%===================
%Convert fonts
%===================
fontSz = 9;
%Convert axes to use nice Latex markings. If subplots are detected then
%loop through them all.
axesHandles = findall(fh,'type','axes');
if (length(axesHandles) > 1)
    for ax = axesHandles(1:end)'
        subplot(ax);
%         set(gca,'FontName','cmr10');
        set(ax,'FontName','Times New Roman','FontSize',fontSz-1);
%         set(ax,'FontName','CMU Serif','FontSize',fontSz);
        grid on;
    end
else 
    axes(axesHandles);
%     set(gca,'FontName','cmr10');
    set(axesHandles,'FontName','Times New Roman','FontSize',fontSz-1);
%     set(axesHandles,'FontName','CMU Serif','FontSize',fontSz);
    grid on;
end

%Make axis labels into latex without changing their size of position. This
%requires getting the position of the string and axes limits before the
%font change, then changing the font, then re-setting the positions.
haxes = findall(fh,'type','axes');
for jj=1:1:length(haxes)
    %Get pre-units and borders and position
    tempunitsaxes = get(haxes(jj),'units');
    set(haxes(jj),'units','inches');
    temppos = get(haxes(jj),'position');
    
    h_axLabels = get(haxes(jj),{'XLabel' 'YLabel'});
    for ii=1:1:length(h_axLabels);
            %Change units to normalized and font to latex
            set(h_axLabels{ii},'interpreter','latex','FontSize',fontSz,'unit','normalized');
    end

    %Reset the position. Matlab seems to mess things up when changing the
    %interpreter to Latex.
    set(haxes(jj),'position',[temppos(1) temppos(2) temppos(3) temppos(4)]);
    
    %Reset original units
    set(haxes(jj),'units',tempunitsaxes);
end

htext = findall(fh,'type','text');
for jj=1:1:length(htext)
    set(h_axLabels{ii},'interpreter','latex','FontSize',fontSz,'unit','normalized');
end

%Make legends latex
ledgs = findobj(gcf,'Type','axes','Tag','legend');
for ii=1:1:length(ledgs) 
    set(ledgs(ii),'interpreter','latex','FontSize',fontSz-1);
    set(ledgs(ii),'PlotBoxAspectRatioMode','manual','PlotBoxAspectRatio',[1.0 0.35 1.0]);
    temppos = get(ledgs(ii),'position');
    set(ledgs(ii),'position',[temppos(1) temppos(2) temppos(3)-0.03 temppos(4)]);
end


%===================
%Make lines correct
%===================
%Set plot lines to be slightly thicker
hline = findobj(fh, 'type', 'line');
set(hline,'linewidth',0.3,'LineSmoothing','on');
%Set axes grid lines thinner
hline = findobj(fh, 'type', 'axis');
set(hline,'linewidth',0.1);

%===================
%Save the pdf or pngcl
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

% open(filename);
end

