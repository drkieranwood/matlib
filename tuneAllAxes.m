disp('Creating control...');

close all;
clear all;
tuneXYControl;
writeSS(reg1,'../controlgains/controlX');
writeSS(reg1,'../controlgains/controlY');

close all;
clear all;
tuneZControl;
writeSS(reg1,'../controlgains/controlZ');

close all;
clear all;
tuneWControl;
writeSS(reg1,'../controlgains/controlW');

close all;
clear all;
disp('...done');