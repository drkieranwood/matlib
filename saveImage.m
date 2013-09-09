function [ filename ] = saveImage( fh , name , XX, YY, overwrite, pdfon)
%SAVEIMAGE Save a .PNG or .PDF image of the specified figure.
%   This function saves a .PNG image of the specified figure. The size of
%   the image in pixels is also specified as width and height. The pixel
%   size may be wrong by a few pixels due to some rounding.
%
%   This function is useful because the .EPS output from Matlab figures
%   does not always display properly and so using a raster image directly
%   from MATLAB is better.
%
%   USEAGE:
%
%   filename = saveImage(fh,'name',XX,YY,overwite,pdfon)
%
%   Where,
%   fh - the matlab figure handle of the image to be saved
%   name - the file name for the image (it will be saved in the current
%   directory)
%   XX - the width in pixels (150 - 9100)
%   YY - the height in pixels (150 - 9100)
%   filename - the saved image filename
%   overwrite - to ignor the overwite file warning
%   pdfon - if set to 1 then output in pdf
%
%   Below 150px the axes and plots might not render correctly, above 9100
%   and the MATLAB save command returns an error.


%Select the specified figure
figure(fh);
plotTickLatex2D;

if nargin < 3
    XX = 1000;
    YY = 1000;
end

if nargin < 4
    YY = 1000;
end

if nargin < 5
    overwrite = 0;
end

if nargin < 6
    pdfon = 0;
end

%150dpi is the default resoloution and is good enought for most
%purposes. 
%NOTE: the dpi will not affect the number of pixels of the final image but
%may affect the image interpretation by other programs.
dpi = 300;
set(fh,'PaperUnits','inches','PaperSize',[XX/dpi YY/dpi],'PaperPosition',[0 0 XX/dpi YY/dpi]);

clear exttt;
if pdfon
        exttt = '.pdf';
        filename = strcat(name, exttt);
else
        exttt = ['.png'];
        filename = strcat(name, exttt);
end


if(~overwrite)
    while exist(filename)
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

if pdfon
    print(fh, '-dpdf', '-r300', filename);
else
    saveas(fh,filename);
     %print(fh,'-dpng','-r150',name);    %An alternative MATLAB save command
end

end

