function [image, M] = toneMapping(im,x,y,im_crop)
%TONEMAPPING given an image and a set of image sampling points effects tone
%mapping, returns the effected image and the tone mapping matrix
arguments (Input)
    im
    x
    y
    im_crop
end

arguments (Output)
    image
    M
end
image = im;
RGBc = [
    115  81  67;
    196 149 129;
    93 123 157;
    90 108  65;
    130 129 176;
    99 191 171;
    220 123  45;
    72  92 168;
    195  84  98;
    91  59 105;
    160 189  62;
    229 161  41;
    43  62 147;
    71 149  72;
    176  48  56;
    238 200  22;
    188  84 150;
    0 136 166;
    245 245 240;
    200 201 201;
    160 161 161;
    120 121 121;
    83  84  85;
    50  50  50 ];  % 24x3 to be taken from the color checker article and divide by 255 (normalize)
    RGBc = rgb2lin(RGBc / 255);
    
    RGB = zeros(24,3);
    x = round(x);
    y = round(y);
    radius = 2;


    % set value for average
    for ii = 1:24
        crop = im_crop(y(ii)-radius:y(ii)+radius, x(ii)-radius:x(ii)+radius, :);
        RGB(ii,:) = mean(reshape(crop, [], 3), 1);
    end
    
    
    M = pinv(RGB) * RGBc;
    S = size(image);
    image = reshape(image, [], 3);
    
    image = image * M;
    
    image = reshape(image, S(1),S(2) ,3);
    image = min(max(image, 0), 1);
    image = lin2rgb(image);
end