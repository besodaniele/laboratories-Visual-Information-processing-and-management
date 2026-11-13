function [image] = AWB(im,method)
%AWB Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    im %original image
    method % method to be used, default grey world (GW). Options are WP (white patch) and MRGB (max rgb)
end

arguments (Output)
    image % output image
end
  
if method == "MRGB"
    image = im;
    R = max(image(:,:,1),[],"all");
    G = max(image(:,:,2),[],"all");
    B = max(image(:,:,3),[],"all");
    

    image(:,:,1) = image(:,:,1) ./ R;
    image(:,:,2) = image(:,:,2) ./ G;
    image(:,:,3) = image(:,:,3) ./ B;

elseif method == "GW"
   

    S = size(im);
    image = reshape(im,[],3);

    avg = mean(image,1);
    coeff = 0.5.*ones(1,3) ./avg;
    image = image * diag(coeff);
    
    image = reshape(image,S);
end


end