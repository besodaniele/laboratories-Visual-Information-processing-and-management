im1 = im2double(imread("godzilla_chromakey\godzilla_1.jpg"));
im2 = im2double(imread("godzilla_chromakey\godzilla_2.jpg"));
S = size(im1);
T = 0.12;
pixels = reshape(im1,[],3);
masks = zeros(size(pixels));
% adatta a fare più crop per avere una bella immagine
for i=1:3
    M = zeros(size(im1,1),1);
    crop = imcrop(im1);
   
    model = reshape(crop,[],3);
    clear crop;
    model = unique(model,"rows");
    
    d = pdist2(pixels,model);
    clear model;
    M(min(d,[],2)>T)=1;

    masks(:,i)=M;
   
end
im1 = reshape(im1,S);
composite = im1;
figure,
subplot(2,3,1),imshow(im1),title("original")
subplot(2,3,2),imshow(im2),title("godzilla")
maskFinal = reshape(masks(:,1),S(1:2));
for i= 1:3
    mask = masks(:,i);
    mask = reshape(mask,S(1:2));
    composite = composite.*mask + im2.*(1-mask);
    subplot(2,3,2+i),imshow(mask),title("mask")
    imwrite(mask,"mask_"+num2str(i)+".png");
    if i>1
        maskFinal = maskFinal .* mask;
    end
end
subplot(2,3,6),imshow(composite),title("composite")
imwrite(composite,"composite.png");
figure,imshow(maskFinal)
imwrite(maskFinal,"maskComplete.png")