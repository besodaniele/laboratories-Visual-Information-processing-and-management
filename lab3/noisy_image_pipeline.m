clear
close all
clc

%% ---------------- settings ----------------
noisyPath = "images\IMG_1295ss_w_noise.tiff";
refPath   = "raw_2_srgb.jpg";   % original JPEG, used as-is

% Parameter grids to test
smoothVals = [0.05:0.05:1];  % DegreeOfSmoothing
sigmaVals  = 1:0.5:8;      % SpatialSigma

Sfactor = 1.2;   % saturation factor

%% ---------------- read noisy image ----------------
im0 = imread(noisyPath);
% convert in double

im0 = im2double(im0);

load max_im;
load min_im;
im0 = (im0 - min_im)./(max_im-min_im);
im0 = min(max(im0, 0), 1); % Clamp values to prevent out-of-bounds pixels

% Reference: gamma-encoded sRGB JPEG, converted to double in [0,1]
ref = im2double(imread(refPath));

% Color correction matrix
load M.mat;

%% ---------------- grid search ----------------
ssimMap = zeros(numel(smoothVals), numel(sigmaVals));

for i = 1:numel(smoothVals)
    for j = 1:numel(sigmaVals)

        % Extract the 4 Bayer planes
        R_plane  = im0(1:2:end, 1:2:end);
        G1_plane = im0(1:2:end, 2:2:end);
        G2_plane = im0(2:2:end, 1:2:end);
        B_plane  = im0(2:2:end, 2:2:end);

        % Multiply the smoothing strength for the noisy color channels

        R_filt  = imbilatfilt(R_plane, smoothVals(i), sigmaVals(j));
        G1_filt = imbilatfilt(G1_plane, smoothVals(i), sigmaVals(j));
        G2_filt = imbilatfilt(G2_plane, smoothVals(i), sigmaVals(j));
        B_filt  = imbilatfilt(B_plane, smoothVals(i), sigmaVals(j));

        % Recombine into a clean Bayer array
        imd = zeros(size(im0));
        imd(1:2:end, 1:2:end) = R_filt;
        imd(1:2:end, 2:2:end) = G1_filt;
        imd(2:2:end, 1:2:end) = G2_filt;
        imd(2:2:end, 2:2:end) = B_filt;

        % Pass the clean Bayer array to the pipeline
        out = run_pipeline(imd, M, Sfactor);
       

        % similarity with the original
        ssimMap(i,j) = ssim(out, ref);
        fprintf("smoothing=%.4f  sigma=%.2f  ->  SSIM=%.4f\n", ...
            smoothVals(i), sigmaVals(j), ssimMap(i,j));
    end
end

%% ---------------- best parameters ----------------
[bestSSIM, idx] = max(ssimMap(:));
[bi, bj] = ind2sub(size(ssimMap), idx);
fprintf("\nBest SSIM = %.4f at smoothing = %.4f, sigma = %.2f\n", ...
    bestSSIM, smoothVals(bi), sigmaVals(bj));

%% ---------------- 3D plot ----------------
[SIG, SM] = meshgrid(sigmaVals, smoothVals); % rows -> smoothing, cols -> sigma

figure(1)
surf(SIG, SM, ssimMap), hold on
plot3(sigmaVals(bj), smoothVals(bi), bestSSIM, 'r.', 'MarkerSize', 30)
set(gca, 'YScale', 'log')       % smoothing values span decades
xlabel('Spatial sigma')
ylabel('Degree of smoothing')
zlabel('SSIM')
title('SSIM vs bilateral filter parameters')
colorbar, shading interp, grid on, view(45, 30)

%% ---------------- final image with best parameters ----------------

R_filt  = imbilatfilt(im0(1:2:end, 1:2:end), smoothVals(bi), sigmaVals(bj));
G1_filt = imbilatfilt(im0(1:2:end, 2:2:end), smoothVals(bi), sigmaVals(bj));
G2_filt = imbilatfilt(im0(2:2:end, 1:2:end), smoothVals(bi), sigmaVals(bj));
B_filt  = imbilatfilt(im0(2:2:end, 2:2:end), smoothVals(bi), sigmaVals(bj));

imd = zeros(size(im0));
imd(1:2:end, 1:2:end) = R_filt;
imd(1:2:end, 2:2:end) = G1_filt;
imd(2:2:end, 1:2:end) = G2_filt;
imd(2:2:end, 2:2:end) = B_filt;

best = run_pipeline(imd, M, Sfactor);
figure(2), imshow(best), title("Best parameters")
figure(3), imshow(ref), title("Reference")

imwrite(best, "raw_2_srgb_noisy.jpg");



%% ---------------- local function ----------------
function im = run_pipeline(im, M, Sfactor)
    im = demosaice(im);
    % AWB (linear)
    im = AWB(im, "MRGB");

    % color correction (linear camera RGB -> linear sRGB)
    S = size(im);
    im = reshape(im, [], 3) * M;
    im = reshape(im, S(1), S(2), 3);
    im = min(max(im, 0), 1);

    % gamma encoding (sRGB), to match the JPEG reference
    im = lin2rgb(im);

    % saturation, applied on the gamma-encoded image
    im = rgb2hsv(im);
    im(:,:,2) = im(:,:,2) * Sfactor;
    im = hsv2rgb(im);

    im = min(max(im, 0), 1);
end