function [img] = demosice(im)
%DEMOSICE given a bayer pattern image with format 
% R G R G
% G B G B
% R G R G
% G B G B
% gives an rgb image trough interpolation
arguments (Input)
    im % bayer image
end

arguments (Output)
    img % rgb image
end
img = zeros(size(im,1),size(im,2),3);
for i=2:size(im,1)-1
    for j=2:size(im,2)-1
        if mod(i,2)==0 && mod(j,2)==0
            % blue pixel 
            img(i,j,1) = mean([im(i-1,j-1), im(i+1,j+1),im(i+1,j-1), im(i-1,j+1)]);
            img(i,j,2) = mean([im(i,j-1), im(i,j+1),im(i+1,j), im(i-1,j)]);
            img(i,j,3) = im(i,j);
        elseif mod(i,2)==1 && mod(j,2)==1
            % red pixel
            img(i,j,1) = im(i,j);
            img(i,j,2) = mean([im(i,j-1), im(i,j+1),im(i+1,j), im(i-1,j)]);
            img(i,j,3) = mean([im(i-1,j-1), im(i+1,j+1),im(i+1,j-1), im(i-1,j+1)]);
        else 
            if mod(i,2) == 0
                % green pixel
                img(i,j,1) = mean([im(i-1,j), im(i+1,j)]);
                img(i,j,2) = im(i,j);
                img(i,j,3) = mean([im(i,j-1), im(i,j+1)]);
            else
                % green pixel
                img(i,j,3) = mean([im(i-1,j), im(i+1,j)]);
                img(i,j,2) = im(i,j);
                img(i,j,1) = mean([im(i,j-1), im(i,j+1)]);
            end

        end
    end
end
end