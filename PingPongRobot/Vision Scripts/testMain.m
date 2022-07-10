% Setup Stuff
clc;	% Clear command window.
close all;	% Close all figure windows except those created by imtool.

% Webcam Number
WEBCAM_NUM = 2;

% Setup cam
cam = webcam(WEBCAM_NUM);

global isRunning;
isRunning = true;

% Set up figure properties.
set(gcf, 'Name', 'Image Testing', 'NumberTitle', 'off') 
set(gcf, 'Toolbar', 'none', 'Menu', 'none');

PushButton = uicontrol(gcf,'Style', 'push', 'String', 'Finish','Position', [0 0 100 70],'CallBack', @PushB);

while isRunning
    
% Get Newest Camera Image
img = snapshot(cam);

% Display the original gray scale image.
subplot(2, 1, 1);
imshow(img, []);
axis off;
title('Original Image', 'FontSize', 20);
end

% !! Get here when we end the program !!
return;
% !! Get here when we end the program !!

% =============================================================
function PushB(source,event)
    % Save
    % exit
    global isRunning;
    isRunning = false;
end