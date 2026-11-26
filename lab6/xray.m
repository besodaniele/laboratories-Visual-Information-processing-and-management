clear
close all
clc
net = alexnet;

basepath = 'chest_xray/';
sz = net.Layers(1).InputSize;

% Load images and labels
imTrain = imageDatastore(fullfile(basepath,'train'), IncludeSubfolders=true, LabelSource='foldernames');
imTest = imageDatastore(fullfile(basepath,'test'), IncludeSubfolders=true, LabelSource='foldernames');

% Automatically resize and convert grayscale to RGB (ignoring already-RGB images)
augTrain = augmentedImageDatastore(sz(1:2), imTrain, ColorPreprocessing='gray2rgb');
augTest  = augmentedImageDatastore(sz(1:2), imTest, ColorPreprocessing='gray2rgb');

labels_tr = imTrain.Labels;
labels_te = imTest.Labels;

layers = ["conv2","conv5","fc8"]; 

for layer = 1:numel(layers)
    fprintf('testando layer %s\n', layers(layer));

    % Extract features
    feat_tr = activations(net, augTrain, layers(layer), OutputAs='rows');
    feat_te = activations(net, augTest, layers(layer), OutputAs='rows');

    % L2 normalization
    feat_tr_norm = feat_tr ./ vecnorm(feat_tr, 2, 2);
    feat_te_norm = feat_te ./ vecnorm(feat_te, 2, 2);

    %% classificazione con 1-NN
    D = pdist2(feat_te,feat_tr);
    [dummy,idx_pred_te] = min(D,[],2);
    lab_pred_te = labels_tr(idx_pred_te);
    acc = numel(find(lab_pred_te == labels_te))/numel(labels_te);
    fprintf('finished with accuracy %.4f for layer %s with non normalized features\n', acc, layers(layer));

    %% classificazione con 1-NN
    D = pdist2(feat_te_norm,feat_tr_norm);
    [dummy,idx_pred_te] = min(D,[],2);
    lab_pred_te = labels_tr(idx_pred_te);
    acc = numel(find(lab_pred_te == labels_te))/numel(labels_te);
    fprintf('finished with accuracy %.4f for layer %s with normalized features\n', acc, layers(layer));
end