clear
close all
clc

%% 1. Grid creation
disp("Creazione griglia...")
imsize = 256;          % Image dimension
featStep = 3;          % Grid step
margin = 6;            % Safety margin

[X, Y] = meshgrid(margin:featStep:imsize-margin, margin:featStep:imsize-margin);
basePts = [X(:), Y(:)];
pointsPosition = [SURFPoints(basePts, 'Scale', 1.6); ...
                  SURFPoints(basePts, 'Scale', 3.2); ...
                  SURFPoints(basePts, 'Scale', 4.8)]; % multiscale

Nim4training = 70;     % Percentage of images for training and validation
Nim4subtrain = 60;     % Train images

%% 2. SURF feature extraction
disp("Estrazione feature SURF per training/validation...")
tic

im_sample = resizeAndCenterCrop(imread('image.orig\0.jpg'), imsize);
[f_sample, ~] = extractFeatures(im2gray(im_sample), pointsPosition, "Method", "SURF");

row_cursor = 1;
for cl = 0:9
    for nimage = 0:Nim4training-1
        im = imread(['image.orig\' num2str(100*cl+nimage) '.jpg']);
        im = resizeAndCenterCrop(im, imsize);
        im_gray = im2gray(im);
        
        [imfeatures, ~] = extractFeatures(im_gray, pointsPosition, "Method", "SURF");
        
        n_pts = size(imfeatures, 1);
        end_row = row_cursor + n_pts - 1;
        
        features_full(row_cursor:end_row, :) = imfeatures;
        labels_full(row_cursor:end_row, :)   = [repmat(cl, n_pts, 1), repmat(nimage, n_pts, 1)];
        row_cursor = end_row + 1;
    end
end

toc

%% 3. Search of best model and grid search of best K for mini batch K means
disp("Ricerca del miglior valore di k e del miglior modello con fitcauto...")
tic
k_candidates = [300, 500, 600];
batchSize    = 8192;
numIters     = 600;

idx_subtr = labels_full(:, 2) < Nim4subtrain;
idx_val   = ~idx_subtr;

features_subtr = features_full(idx_subtr, :);
labels_subtr   = labels_full(idx_subtr, :);
features_val   = features_full(idx_val, :);
labels_val     = labels_full(idx_val, :);

best_val_acc = -1;
best_k       = k_candidates(1);
best_c       = [];
FinalModel   = [];

opts_search = struct( ...
    'MaxObjectiveEvaluations', 90, ...
    'Verbose', 0 ...
);

for k_idx = 1:length(k_candidates)
    curr_k = k_candidates(k_idx);
    fprintf('\n========================================================\n');
    fprintf('--- Testando Mini-Batch K-Means + fitcauto con k = %d ---\n', curr_k);
    fprintf('========================================================\n');
    
    rng(42);
    c_sub = miniBatchKMeans(features_subtr, curr_k, batchSize, numIters);
    
    [BOW_subtr, y_subtr] = buildBOW(features_subtr, labels_subtr, c_sub, curr_k, 0, Nim4subtrain-1);
    [BOW_val,   y_val]   = buildBOW(features_val,   labels_val,   c_sub, curr_k, Nim4subtrain, Nim4training-1);
    
    rng(42);
    mdl_k = fitcauto(BOW_subtr, y_subtr, ...
        'HyperparameterOptimizationOptions', opts_search);
    
    preds_val = predict(mdl_k, BOW_val);
    val_acc = sum(preds_val == y_val) / numel(y_val) * 100;
    
    fprintf('\n>>> Risultato k = %d (%s) -> Validation Accuracy: %.2f%%\n', ...
            curr_k, class(mdl_k), val_acc);
    
    if val_acc > best_val_acc
        best_val_acc = val_acc;
        best_k       = curr_k;
        best_c       = c_sub;
        FinalModel   = mdl_k;
    end
end
toc

fprintf('\n========================================================\n');
fprintf('MIGLIOR COPPIA TROVATA (Option A):\n');
fprintf('k = %d | Modello = %s | Validation Accuracy = %.2f%%\n', ...
        best_k, class(FinalModel), best_val_acc);
fprintf('========================================================\n\n');
disp(FinalModel);

%% 4. Feature extraction on test set and model evaluation
disp("Valutazione finale sul test set")
tic
BOW_te    = [];
labels_te = [];

for cl = 0:9
    for nimage = Nim4training:99
        im = imread(['image.orig\' num2str(100*cl+nimage) '.jpg']);
        im = resizeAndCenterCrop(im, imsize);
        im_gray = im2gray(im);
        
        [imfeatures, ~] = extractFeatures(im_gray, pointsPosition, "Method", "SURF");
        
        words = assignWordsChunked(imfeatures, best_c, 50000);
        
        h_bow = histcounts(words, 1:(best_k+1));
        h_bow = h_bow ./ sum(h_bow);
        
        BOW_te    = [BOW_te; h_bow];
        labels_te = [labels_te; cl];
    end
end

predicted_class = predict(FinalModel, BOW_te);
toc

%% 5. Misurazione performance finale
figure;
confusionchart(labels_te, predicted_class, ...
    'Normalization', 'row-normalized', ...
    'Title', sprintf('Test Confusion Matrix (Mini-Batch k=%d, %s)', best_k, class(FinalModel)));

cm = confusionmat(labels_te, predicted_class);
cm_norm = cm ./ sum(cm, 2);
avg_accuracy = mean(diag(cm_norm), 'omitnan');
disp(['Average Diagonal Accuracy sul Test Set: ', num2str(avg_accuracy * 100), '%']);
disp(["model used", class(FinalModel), " with number of clusters", best_k])

function centroids = miniBatchKMeans(X, k, batchSize, numIters)
    N = size(X, 1);
    batchSize = min(batchSize, N);
    
    initIdx = randperm(N, k);
    centroids = double(X(initIdx, :));
    counts = zeros(k, 1);
    
    for iter = 1:numIters
        batchIdx = randperm(N, batchSize);
        B = double(X(batchIdx, :));
        
        D = pdist2(B, centroids);
        [~, nearest] = min(D, [], 2);
        
        for j = 1:k
            assigned = (nearest == j);
            n_assigned = sum(assigned);
            if n_assigned > 0
                counts(j) = counts(j) + n_assigned;
                eta = n_assigned / counts(j);
                batch_mean = mean(B(assigned, :), 1);
                centroids(j, :) = (1 - eta) * centroids(j, :) + eta * batch_mean;
            end
        end
    end
end

function all_words = assignWordsChunked(feats, centroids, chunkSize)
    % Evita errori di memoria (Out of Memory) quando feats ha milioni di righe
    N = size(feats, 1);
    all_words = zeros(N, 1, 'int32');
    centroids_s = single(centroids);
    
    for startIdx = 1:chunkSize:N
        endIdx = min(startIdx + chunkSize - 1, N);
        D = pdist2(single(feats(startIdx:endIdx, :)), centroids_s);
        [~, w] = min(D, [], 2);
        all_words(startIdx:endIdx) = int32(w);
    end
end

function [BOW_mat, y_vec] = buildBOW(feats, meta_labels, centroids, k, start_img, end_img)
    all_words = assignWordsChunked(feats, centroids, 50000);
    
    num_imgs = 10 * (end_img - start_img + 1);
    BOW_mat = zeros(num_imgs, k);
    y_vec   = zeros(num_imgs, 1);
    
    row = 1;
    for cl = 0:9
        for ni = start_img:end_img
            idx_pts = (meta_labels(:,1) == cl) & (meta_labels(:,2) == ni);
            words = all_words(idx_pts);
            
            h_bow = histcounts(words, 1:(k+1));
            h_bow = h_bow ./ sum(h_bow);
            
            BOW_mat(row, :) = h_bow;
            y_vec(row)      = cl;
            row = row + 1;
        end
    end
end

function im_out = resizeAndCenterCrop(im, targetSize)
    [h, w, ~] = size(im);
    if h < w
        im = imresize(im, [targetSize, NaN]);
    else
        im = imresize(im, [NaN, targetSize]);
    end
    win = centerCropWindow2d(size(im), [targetSize, targetSize]);
    im_out = imcrop(im, win);
end