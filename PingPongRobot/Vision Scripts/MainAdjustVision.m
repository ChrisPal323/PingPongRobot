% Setup Stuff
clc;	% Clear command window.
close all;	% Close all figure windows except those created by imtool.

% Webcam Number
WEBCAM_NUM = 2;

% Setup cam
cam = webcam(WEBCAM_NUM);
runLoop = true;

% ----- Adjustable Paramters ------
% 1 is perfect white, 0 is perfect black
colorThresh = 0.7;
smallestAcceptableArea = 150;
global minCirulairty;
minCirulairty = 0.6;
% ----- Adjustable Paramters ------

% ------------- GUI Constructor  -------------
global GUI
GUI = AdjustVision_Figure();
pause(3); % Wait to boot up fig
% ------------- GUI Constructor  -------------

% ------------- Calibration Function -------------

% Run Calibration Sequence to get HSV values of the ball 
calibrateHSVThreshold(cam)

% ------------- Viewing Loop -------------

while runLoop
    
    % Get Newest Camera Image
    img = snapshot(cam);
    img = imresize(img,[240 426]);
    
    % Parse via HSV colorspace with slider values
    coloredObjectsMask = MaskHSVFromRGB(img);
    
    % Parse Mask to Find minimum sized and unquie blobs and its respective data
    [propertyDataSet, uniqueBlobs] = FindBlobData(coloredObjectsMask, smallestAcceptableArea);
    
    % Find blob with the max Ciculairty Constant (greater than 'minCirulairty')
    maxCirulairtyElementNum = FindMaxCirculairtyElement(propertyDataSet, uniqueBlobs);
    
    % Locates the position of the indicated blob's centroid
    centroidPosition = LocateCentriod(propertyDataSet, maxCirulairtyElementNum);
    
    % Display Camera Image with Centroid Location
    ShowImageWithCentroid(img, coloredObjectsMask, centroidPosition);
    
    % If save button pressed, stop running and save
    if (GUI.buttonVal)
        runLoop = false;
    end
end

% Save HSV Values to file
% open your file for writing
fid = fopen('HSV_Values.txt','wt');
% write the matrix
fprintf(fid,'%d %d %d\n', GUI.getSliderValues);
fclose(fid);

% Get Here to End the Program
return;

% ------------- END Testing Loop -------------

% Run inital calibration sequence to get HSV values of the ball
function calibrateHSVThreshold(webcam)
    
    % Show inital Frame
    %img = snapshot(webcam);

    % Have user select the ball with a drag and draw circle
    
end

% Used to convert the RGB to thresholded HSV from sliders
function mask = MaskHSVFromRGB(image)

    % Find GUI values
    global GUI;
    vals = GUI.getSliderValues();

    % Convert
    hsvImage = rgb2hsv(image);
    
    % Extract out the H, S, and V images individually
	hImage = hsvImage(:,:,1);
	sImage = hsvImage(:,:,2);
	vImage = hsvImage(:,:,3);
    
    % Now apply each color band's particular thresholds to the color band
	hueMask = (hImage >= vals(1)) & (hImage <= vals(2));
	saturationMask = (sImage >= vals(3)) & (sImage <= vals(4));
	valueMask = (vImage >= vals(5)) & (vImage <= vals(6));
    
    % Combine H,S, and V masks
    tempMask = uint8(hueMask & saturationMask & valueMask);
    
    % Smooth the border using a morphological closing operation, imclose()
    structuringElement = strel('disk', 4);
	mask = imclose(tempMask, structuringElement);
end


% Used to find Blob Data from Mask
function [dataSet, blobs] = FindBlobData(mask, smallestAcceptableArea)
    
    % Label each blob so we can make measurements of it
    [labeledImage, numberOfBlobs] = bwlabel(mask, 8);
                                          
    % Remove small components
    for i = 1:numberOfBlobs
       if(sum(sum(labeledImage==i)) < smallestAcceptableArea)
           labeledImage(labeledImage==i)=0;
       end
    end
    
    % Parse through blobs and find unique, non-repeated blobs
    blobs = unique(labeledImage);
     
    % Find the properties of the image
    dataSet = regionprops(labeledImage, 'all');
end


% Used to Find the element with max circulairty value
function eleNum = FindMaxCirculairtyElement(Sdata, Un)

    % Get minCir Threshold
    global minCirulairty;
    
    % Init eleNum
    eleNum = 0;

    % First off, check if Ahhh, no data, send back 0 cause sadly, no data
    if (isempty(Sdata))
        eleNum = 0;
        return
    end

    % Check for Max Circulairty
    % Circulairty = 4*PI*Area/Perimeter.^2
    maxCir = 0.0;
    for i=2:numel(Un)
          Circulairty = (4*pi*Sdata(Un(i)).Area)/Sdata(Un(i)).Perimeter.^2;
          maxCir = max(maxCir,Circulairty);

          if(Circulairty == maxCir)
              % Passes minCir Threshold
              if (maxCir >= minCirulairty) 
                  eleNum = Un(i);
              else
                  % Doesn't pass threshold
                  eleNum = 0;
              end
          end
    end
end


% Finds location of blob centroid, ? if none
function cen = LocateCentriod(dataSet, eleNum)
    
    % If this is 0 than no data collected
    if (eleNum == 0)
        cen = 0;
        return
    end
    
    % There is data, so Find the centroid
    cen=dataSet(eleNum).Centroid;
end


% Used to Display image with Centroid Positon
function ShowImageWithCentroid(img, thresh, cenPos)

    % GUI values
    global GUI
    thresh = 255 * repmat(uint8(thresh), 1, 1, 3);
    
    % If there are points, plot them on the image
    if (cenPos ~= 0)
        img = insertMarker(img,[cenPos(1,1) cenPos(1,2)],'x','color','red','size',6);
    end
    
    % Push to GUI
    GUI.Image.ImageSource = img;
    GUI.ImageThresh.ImageSource = thresh;

end
