clear
close all
clc
image = imread("images\underexposed.jpg");
image_new = rgb2ycbcr(image);
canaleY = double(image_new(:,:,1));
%% mask creation 
mask_gauss = 255-imgaussfilt(canaleY,10);

mask_bil = 255-imbilatfilt(canaleY);
%% gamma correction
output_gauss = 255* (canaleY/255).^(2.^((128-mask_gauss)/128));

output_bil = 255* (canaleY/255).^(2.^((128-mask_bil)/128));
%% gauss 
image_new_gauss = image_new;

image_new_gauss(:,:,1) = output_gauss;

image_new_gauss = uint8(ycbcr2rgb(image_new_gauss));

figure(1),montage({uint8(mask_gauss),image_new_gauss}),title("gaussian filter")
%% bilateral
image_new_bil = image_new;

image_new_bil(:,:,1) = output_bil;

image_new_bil = uint8(ycbcr2rgb(image_new_bil));

figure(2),montage({uint8(mask_gauss),image_new_bil}),title("bilateral filter")

%% difference of masks
        