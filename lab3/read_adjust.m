function [im,max_im,min_im] = read_adjust(file)
% reads a raw image and returns an image in standard range
arguments (Input)
    file % raw image file to be red
end

arguments (Output)
    im
    max_im
    min_im
end
% read image

im = imread(file);
% convert in double

im = im2double(im);

max_im = max(im(:));
min_im = min(im(:));


im = (im - min_im)./(max_im-min_im);
im = min(max(im, 0), 1); % Clamp values to prevent out-of-bounds pixels
end