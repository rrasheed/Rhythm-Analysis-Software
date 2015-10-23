function [cmosData,frequency,bgimage] = iDSconverter(directory,filename)

%create object for loading video
a = mmreader([directory '/' filename]);

%save out video settings
nFrames = a.NumberOfFrames;
vidHeight = a.Height;
vidWidth = a.Width;

% Preallocate movie structure.
mov(1:nFrames) = ...
    struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
    'colormap', []);

cmosData = zeros(vidHeight,vidWidth,nFrames);

%save out single grayscale image for each frame
for k = 1 : nFrames
    mov(k).cdata = read(a, k);
    cmosData(:,:,k) = rgb2gray(mov(1,k).cdata);
end

% cmosData = -cmosData;

frequency = a.FrameRate;

bgimage = sum(cmosData(:,:,1:4),3)/4;

save([filename(1:end-3) 'mat'],'cmosData','frequency','bgimage');

end

