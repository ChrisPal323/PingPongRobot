% Setup Stuff
clc;	% Clear command window.
close all;	% Close all figure windows except those created by imtool.

% Get Webcam Number from Paths
fileID = fopen('../Data/Cam_Paths.txt','r');
formatSpec = '%f';
camVals = fscanf(fileID, formatSpec);

%  ------- Grab First or Second Cam -------
WEBCAM_NUM = 1; % 1 or 2
%  ------- Grab First or Second Cam -------

% Get the cam value
webcamPath = camVals(WEBCAM_NUM);

% Setup cam
cam = webcam(webcamPath);
runLoop = true;

% ------------- GUI Constructor  -------------
global GUI
GUI = AdjustVision_Figure();
pause(1); % Wait to boot up fig
% ------------- GUI Constructor  -------------

% ------- Read Previous Tracking Values ---------
filePath = strcat('../Data/Tracking_Values', string(WEBCAM_NUM), '.txt');
fileID = fopen(filePath,'r');
formatSpec = '%f';
prevVals = fscanf(fileID, formatSpec);

% Set Slider to that value
GUI.setSliderValues(prevVals);
% ------- Read Previous Tracking Values ---------


% ------------- Viewing Loop -------------

while runLoop
    
    % Get Newest Camera Image
    img = snapshot(cam);
    img = imresize(img,[240 426]);
    
    % Parse via HSV colorspace with slider values
    coloredObjectsMask = MaskHSVFromRGB(img);
    
    % Parse Mask to Find minimum sized and unquie blobs and its respective data
    [propertyDataSet, uniqueBlobs] = FindBlobData(coloredObjectsMask);
    
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
% open file for writing
fid = fopen('Tracking_Values.txt','wt');
% write the array
fprintf(fid,'%f\n', GUI.getSliderValues);
fprintf(fid,'%f\n', get(GUI.smallArea,'Value'));
fprintf(fid,'%f\n', get(GUI.minCir,'Value'));
fclose(fid);

% Get Here to End the Program
GUI.delete
error("Exited & Saved Successfully");

% ------------- END Testing Loop -------------


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
function [dataSet, blobs] = FindBlobData(mask)

    % get GUI vals
    global GUI;
    
    % Label each blob so we can make measurements of it
    [labeledImage, numberOfBlobs] = bwlabel(mask, 8);
                                          
    % Remove small components
    for i = 1:numberOfBlobs
       if(sum(sum(labeledImage==i)) < get(GUI.smallArea,'Value'))
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

    % get GUI vals
    global GUI;
    
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
              if (maxCir >= get(GUI.minCir,'Value')) 
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
