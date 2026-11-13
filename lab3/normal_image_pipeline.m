clear
close all
clc
%% read image
[im, max_im, min_im ]= read_adjust("images\IMG_1295ss.tiff");
save max_im;
save min_im;
figure(1),imshow(im);

%% demosaicing

im = demosaice(im);
figure(),imshow(im);

%% AWB

% GW, TODO: implement whitepatch or whitepoint or MaxRGB
im = AWB(im,"MRGB");

figure(4),imshow(im);

%% color correction -> can be reused for any image

im_crop = imcrop(im);
im_crop = imresize(im_crop,10);
figure(5),imshow(im_crop);
[x,y] = ginput(24);
[im, M] = colorCorrection(im,x,y,im_crop);
save M;
figure(5),imshow(im);
%% tone mapping / image enhancement 

Sfactor = 1.2; 
im = rgb2hsv(im);
im(:,:,2) = im(:,:,2) * Sfactor;
im = hsv2rgb(im);
figure(6),imshow(im);

%% jpeg compression
imwrite(im2uint8(im),"raw_2_srgb.jpg");
