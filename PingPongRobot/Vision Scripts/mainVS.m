% Setup Stuff
clc;	% Clear command window.
close all;	% Close all figure windows except those created by imtool.

% Setup cam
cam = webcam(2);

% ----- Adjustable Paramters ------
% 1 is perfect white, 0 is perfect black
colorThresh = 0.7;
smallestAcceptableArea = 300;
minCirulairty = 0.4;
% ----- Adjustable Paramters ------

% Create Slider Figures to Adjust HSV Values
sliderObjectArray = createParamAdjustFigure();

% ------------- Testing Loop -------------
while true
    
    % Run Calibration Sequence to get HSV values of the ball 
    calibrateHSVThreshold()
    
    % Get Newest Camera Image
    img = snapshot(cam);
    
    % Parse via HSV colorspace with slider values
    coloredObjectsMask = MaskHSVFromRGB(img, sliderObjectArray);
    
    % Parse Mask to Find minimum sized and unquie blobs and its respective data
    [propertyDataSet, uniqueBlobs] = FindBlobData(coloredObjectsMask, smallestAcceptableArea);
    
    % Find blob with the max Ciculairty Constant (greater than 'minCirulairty')
    maxCirulairtyElementNum = FindMaxCirculairtyElement(propertyDataSet, uniqueBlobs);
    
    % Locates the position of the indicated blob's centroid
    centroidPosition = LocateCentriod(propertyDataSet, maxCirulairtyElementNum);
    
    % Display Camera Image with Centroid Location
    ShowImageWithCentroid(img, centroidPosition);
    
    % Update the HSV values to better match the balls
    
    
end
% ------------- Testing Loop -------------

% Run inital calibration sequence to get HSV values of the ball
function calibrateHSVThreshold()
    % Show inital Frame
    img = snapshot(cam);
    imshow(img);
    
    % Have user select the ball with a drag and draw circle
    
    
    % Get average values from the circle selected
end

% Used to create firgure for the sliders for thresholding the HSV figure
function sliderObjectArray = createParamAdjustFigure()

    paramFig = uifigure('Name','Image Parameters');
    
    btn = uibutton(paramFig, 'Position', [250,130,100,22], 'Text', 'Save & Exit');

    uilabel(paramFig,'Text', 'H', 'Position', [40 50 100 60]);
    uilabel(paramFig,'Text', 'S', 'Position', [40 190 100 60]);
    uilabel(paramFig,'Text', 'V', 'Position', [40 330 100 60]);
    
    sldUpperH = uislider(paramFig, 'Value', 0.3, 'Position', [85 50 435 3], 'Limits', [0 1], 'MajorTicks', [0 0.25, 0.5, 0.75, 1]);
    sldLowerH = uislider(paramFig, 'Value', 0.05, 'Position', [85 110 435 3], 'Limits', [0 1], 'MajorTicks', [0 0.25, 0.5, 0.75, 1]);

    sldUpperS = uislider(paramFig, 'Value', 1, 'Position', [85 190 435 3], 'Limits', [0 1], 'MajorTicks', [0 0.25, 0.5, 0.75, 1]);
    sldLowerS = uislider(paramFig, 'Value', 0, 'Position', [85 250 435 3], 'Limits', [0 1], 'MajorTicks', [0 0.25, 0.5, 0.75, 1]);

    sldUpperV = uislider(paramFig, 'Value', 1, 'Position', [85 330 435 3], 'Limits', [0 1], 'MajorTicks', [0 0.25, 0.5, 0.75, 1]);
    sldLowerV = uislider(paramFig, 'Value', 0.85, 'Position', [85 390 435 3], 'Limits', [0 1], 'MajorTicks', [0 0.25, 0.5, 0.75, 1]);
    
    sliderObjectArray = [sldUpperH, sldLowerH, sldUpperS, sldLowerS, sldUpperV, sldLowerV];
    
end

% Used to convert the RGB to thresholded HSV from sliders
function mask = MaskHSVFromRGB(image, sliderObjectArray)

    % Convert
    hsvImage = rgb2hsv(image);
    
    % Extract out the H, S, and V images individually
	hImage = hsvImage(:,:,1);
	sImage = hsvImage(:,:,2);
	vImage = hsvImage(:,:,3);
    
    % Now apply each color band's particular thresholds to the color band
	hueMask = (hImage >= sliderObjectArray(2).Value) & (hImage <= sliderObjectArray(1).Value);
	saturationMask = (sImage >= sliderObjectArray(4).Value) & (sImage <= sliderObjectArray(3).Value);
	valueMask = (vImage >= sliderObjectArray(6).Value) & (vImage <= sliderObjectArray(5).Value);
    
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
              eleNum = Un(i);
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
function ShowImageWithCentroid(img, cenPos)
    
    % Display the image and mark centroid, only if it exists
	imshow(img, []);
    hold on
    if (cenPos ~= 0)
        plot(cenPos(1,1),cenPos(1,2), 'rx');
    end
    hold off 
end