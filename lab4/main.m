close all
clear 
clc
boxImage = imread("immaginiObjectDetection\elephant.jpg");
sceneImage = imread("immaginiObjectDetection\clutteredDesk.jpg");

boxPoints = detectSURFFeatures(boxImage, "MetricThreshold", 1.0, "NumScaleLevels",10,"NumOctaves",20);
scenePoints = detectSURFFeatures(sceneImage, "MetricThreshold", 1.0, "NumScaleLevels", 10,"NumOctaves",20);
disp([boxPoints.Count scenePoints.Count])

figure(1),clf
imshow(boxImage),hold on
plot(selectStrongest(boxPoints,100)), hold off

figure(2),clf
imshow(sceneImage),hold on
plot(selectStrongest(scenePoints,100)), hold off

% calculate features

[boxFeatures, boxPoints] = extractFeatures(boxImage, boxPoints);
[sceneFeatures, scenePoints] = extractFeatures(sceneImage, scenePoints);

% match features
boxPairs = matchFeatures(boxFeatures, sceneFeatures,"MatchThreshold",50,"MaxRatio",0.9,"Unique",false);
matchedBoxPoints = boxPoints(boxPairs(:,1), :);
matchedScenePoints = scenePoints(boxPairs(:,2), :);

figure(3), clf
showMatchedFeatures(boxImage, sceneImage, matchedBoxPoints, matchedScenePoints, "montage");
title("Matched Features");

% remove outliers

[tform, inlierBoxPoints, inlierScenePoints] = estimateGeometricTransform( ...
    matchedBoxPoints, matchedScenePoints, "affine");

figure(4), clf
showMatchedFeatures(boxImage, sceneImage, inlierBoxPoints, inlierScenePoints, "montage");
title("Inlier Matches");

% bbox drawing

boxPoly = [1 1;
    size(boxImage,2) 1 ;
    size(boxImage,2) size(boxImage,1);
    1 size(boxImage,1);
    1 1];

% Transform the object bounding-box corners into scene coordinates
newBoxPoly = transformPointsForward(tform, boxPoly);

figure(5), clf
imshow(sceneImage), hold on
line(newBoxPoly(:,1), newBoxPoly(:,2), ...
    "Color","y","LineWidth",2), hold off
    
more precise bbox
figure(6),clf
imshow(boxImage)
[x,y] = ginput(40);
x = [x; x(1)];
y = [y; y(1)];


newBoxPoly = transformPointsForward(tform ,[x y]);
figure(7),clf
imshow(sceneImage), hold on
line(newBoxPoly(:,1), newBoxPoly(:,2), ...
    "Color","y")
hold off