close all;
clear;
clc;
im1Original = imread("colorTransfer\seraLago.jpeg");
im2Original = imread("colorTransfer\night.jpg");
%convert to double

im1 = im2double(im1Original);
im2 = im2double(im2Original);

im1_ycbcr = rgb2ycbcr(im1);
im2_ycbcr = rgb2ycbcr(im2);

im1_ycbcr = reshape(im1_ycbcr,[],3);
im2_ycbcr = reshape(im2_ycbcr,[],3);

mean1 = mean(im1_ycbcr);
mean2 = mean(im2_ycbcr);

std1 = std(im1_ycbcr);
std2 = std(im2_ycbcr);

% color transfer

im1_ycbcr(:,2) = (im1_ycbcr(:,2)-mean1(2)) * (std2(2)/std1(2)) + mean2(2); 
im1_ycbcr(:,3) = (im1_ycbcr(:,3)-mean1(3)) * (std2(3)/std1(3)) + mean2(3); 

% recreate

im1_ycbcr = reshape(im1_ycbcr,size(im1));
im2_ycbcr = reshape(im2_ycbcr,size(im2));

im1 = ycbcr2rgb(im1_ycbcr);
im1 = im2uint8(im1);

im2 = ycbcr2rgb(im2_ycbcr);
im2 = im2uint8(im2);


figure, subplot(1,3,1),imshow(im1Original);
subplot(1,3,2),imshow(im2Original);
subplot(1,3,3),imshow(im1);
