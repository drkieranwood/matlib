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

%Select the specified figure
figure(fh);

%Convert axes to use nice Latex markings
plotTickLatex2D;

%If the image size is not specified then use 1000x1000px
if nargin < 3
    XX = 1000;
    YY = 1000;
end
if nargin < 4
    YY = 1000;
end

%If the overwrite is not specified then do NOT overwrite
if nargin < 5
    overwrite = 0;
end

%If the pdf is not specified then output png
if nargin < 6
    pdfon = 0;
end

%Remove the white space matlab puts around its axes. Get the axes bounding
%box and then use the location to adjust the position
tightInset = get(fh,'TightInset');
pos(1) = tightInset(1);
pos(2) = tightInset(2);
pos(3) = 1 - tightInset(1) - tightInset(3);
position(4) = 1 - tightInset(2) - tightInset(4);
set(gca, 'Position', position);
saveas(h, 'WithoutMargins.pdf');

%300dpi is the default resoloution and is good enough for most
%purposes. The dpi will not affect the number of pixels in the final image but
%may affect how the image is interpreted by other programs.

%Set the page size to be exactly the correct size to be 300dpi. Place the
%figure in the bottom corner and make it fill the page.
dpi = 300;
set(fh,'PaperUnits','inches','PaperPositionMode','manual','PaperSize',[XX/dpi YY/dpi],'PaperPosition',[0 0 XX/dpi YY/dpi],'Units','inches');

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
    print(fh, '-dpdf', '-r300', filename);
else
    print(fh,'-dpng','-r300',filename);
end

end

